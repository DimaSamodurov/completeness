# Completeness

"Completeness" calculates percentage of populated fields of the object.

It helps answering common questions: 'how complete the user profile is?' and 'what information is missing?'.


## Installation

Add to Gemfile

    gem git: 'git@github.com:DimaSamodurov/completeness.git'

## Usage

```ruby
class Profile
  attr_accessor :first_name, :last_name, :email, :phone, :addresses

  include Completeness

  define_completeness(
    {
        first_name:  { :if => 'present?', add: 20 },
        last_name:   { :if => 'present?', add: 20 },
        email:       { :if => 'present?', add: 40, boolean_method: 'email_provided?' },
        addresses:   { :if => 'any?',     add: 20, boolean_method: 'address_provided?' },
    }
  )
end

p = Profile.new
p.completeness         # => 0
p.complete?            # => false
p.first_name, p.last_name, p.email = %w(John Doe john.doe@mail.net)
p.completeness         # => 80
p.complete?            # => false
p.address_provided?    # => false
p.addresses = ['Crater Grimaldi, Moon, 5.2°S 68.6°W']
p.address_provided?    # => true
p.completeness         # => 100
p.complete?            # => true
```


## Testing

    rake test

## Doc

    yard doc

## Possible enhancement

- allow proc to be passed as "if" option
- validate sum = 100%
- eliminate ActiveSupport depencency
- configure defaults like {:if => 'nil?'}

