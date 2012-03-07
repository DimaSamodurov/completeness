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

  # More complex condition can be if object has several states depended on e.g workflow or permissions.
  # In that case list of shares can vary for different objects.
  # Then we can add flipper like :when => lambda { self.has_extended_properties? }

  # Return completeness weight of the field configured for current object
  def completeness_share_of(field)
    completeness_shares[field] or raise "Completeness share is not defined for '#{field}' of #{self.class.name}"
  end

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
  def incomplete_items
    completeness_shares.keys.select{|field| completeness_of(field) == 0 }
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

end