require "completeness/version"
require "active_support/concern"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/class"


# Helps calculate the percent of populated fields of the object
# ==== Examples
#   class Profile
#     attr_accessor :addresses
#     include Completeness
#     completeness_shares = { addresses: {:if => 'any?', weight: 20} }
#   end
#
#   p = Profile.new
#   p.completeness # => 0 . No exception even 'addresses' is nil and does not respond to 'any?'
#   p.addresses = []
#   p.completeness # => 0. Still works as [].any? == false
#   p.addresses << 'Location 1'
#   p.completeness # => 20
#
module Completeness
  extend ActiveSupport::Concern

  #completeness_shares =
  #    {
  #        contact_email:  { :if => 'present?', weight: 60 },
  #        contact_phone:  { :if => 'present?', weight: 40 },
  #    }

  included do
    self.class_attribute :completeness_defaults
    self.completeness_defaults = {:if => "present?"}

    self.class_attribute :completeness_shares
    self.completeness_shares = {}
  end

  module ClassMethods

    def define_completeness(shares, custom_options = {} )
      default_options = {
          define_boolean_methods: true,
          validate_shares: true
      }
      options = default_options.merge custom_options
      self.completeness_shares = shares

      completeness_validate_shares        if options[:validate_shares]
      completeness_define_boolean_methods if options[:define_boolean_methods]
    end

    # Returns completeness weight option of the field
    def completeness_weight_of(field)
      completeness_share_of(field)[:weight]
    end

    # Returns title of the field:
    # - as :title option
    # - as humanized field name if :title option is not specified
    def completeness_title_of(field)
      completeness_share_of(field)[:title] || field.to_s.humanize.split.map(&:capitalize).join(' ')
    end

    # Return completeness weight of the field configured for current object
    def completeness_share_of(field)
      completeness_shares[field] or raise "Completeness share is not defined for '#{field}' of #{self.class.name}"
    end

    protected

    # let we have defined completeness on user model like:
    #  {
    #    email:      { title: 'Email address', weight: 80 }
    #    addresses:  { title: 'Addresses',  weight: 20, boolean_method: 'address_provided' },
    #  }
    # then you will get user.address_provided? method defined which return true in case weight of this field > 0.
    # we defined additional field instead of using user.addresses.present? because it will return true for empty array.
    def completeness_define_boolean_methods
      completeness_shares.each do |field, meta|
        if meta[:boolean_method]

          method_name = "#{meta[:boolean_method]}".to_sym

          raise "Oops, #{method_name} is already defined on the #{self.class.name}." +
                " Consider another name for boolean field." if method_defined? method_name

          define_method method_name do
            completeness_of(field) > 0
          end
        end
      end
    end

    def completeness_validate_shares
      sum = completeness_shares.values.map{|share| share[:weight]}.inject(0) { |sum, value| sum + value }
      raise "Expected completeness weights sum to be 100, but got #{sum}." if sum != 100
    end
  end

  include ClassMethods

  # More complex condition can be if object has several states depended on e.g workflow or permissions.
  # In that case list of shares can vary for different objects.
  # Then we can add flipper like :when => lambda { self.has_extended_properties? }


  # Determines completeness of 'field' based on +completeness_shares+ conditions.
  # Conditions are verified softly, not raising exception when rule is not applicable.
  def completeness_of(field)
    share = completeness_share_of(field)
    self.send(field).try((share[:if] || self.completeness_defaults[:if]).to_sym) ? share[:weight] : 0
  end

  # Calculates sum of weights of all complete fields
  def completeness
    completeness_shares.keys.inject(0) do |result, field|
      result += completeness_of(field)
    end
  end

  # True if completeness = 100%. In other words if all fields are complete.
  def complete?
    completeness == 100
  end

  # Returns fields whose completeness = 0
  def incomplete_fields
    completeness_shares.keys.select{|field| completeness_of(field) == 0 }
  end

end