require_relative 'minitest_helper'

class Profile

  attr_accessor :first_name, :last_name, :email, :phone, :addresses

  include Completeness

  self.completeness_shares =
      {
          first_name:  { :if => 'present?', weight: 20 },
          last_name:   {                    weight: 20 }, # used default :if
          email:       {                    weight: 30 },
          phone:       {                    weight: 10 },
          addresses:   { :if => 'any?',     weight: 20 },
      }
end

describe Completeness do

  describe "completeness_shares" do
    it "define completeness percent of fields" do
      p = Profile.new
      p.completeness.must_equal 0
      p.complete?.must_equal false

      p.first_name = 'John' and p.completeness.must_equal 20
      p.last_name = 'Doe' and p.completeness.must_equal 40
      p.email = 'john.doe@mail.net' and p.completeness.must_equal 70
      p.phone = '333222' and p.completeness.must_equal 80
      p.addresses = ["City,State,Zip"] and p.completeness.must_equal 100

      p.complete?.must_equal true
    end

    describe " 'if' condition" do
      it "default is 'present?' " do
        p = Profile.new
        p.email = '   '
        p.completeness_of(:email).must_equal 0 # as spaces considered as blank.
        p.email = 'john@mail.com'
        p.completeness_of(:email).must_equal 30
      end
    end

    it "can be overridden at the object level" do
      p = Profile.new
      p.completeness_shares =
          {
            first_name:  { weight: 45.5 },
            email:       { weight: 54.5 }
          }
      p.first_name = 'Joe'
      p.completeness.must_equal 45.5
      p.email = 'joe@mail.net'
      p.completeness.must_equal 100
      p.complete?.must_equal true
    end
  end

  describe "completeness_of(field)" do
    it "should return :weight of the field specified if the field conform 'if' condition" do
      p = Profile.new
      p.first_name = 'John'
      p.completeness_of(:first_name).must_equal 20
    end

    it "should raise exception for unknown field" do
      p = Profile.new
      proc { p.completeness_of(:abrakadabra) }.must_raise RuntimeError
    end
  end

  it "can be included to the object" do
    class Foo
      attr_accessor :baz, :bar
    end
    f = Foo.new
    f.singleton_class.instance_eval do
      include Completeness
      self.completeness_shares = { baz: { weight: 41 }, bar: { weight: 59 } }
    end
    f.complete?.must_equal false
    f.baz = 'catch'
    f.completeness.must_equal 41
    f.bar = 'me'
    f.completeness.must_equal 100
  end

  describe "incomplete_items" do
    it "should return names of items having zero completeness" do
      p = Profile.new
      p.incomplete_items.must_equal [:first_name, :last_name, :email, :phone, :addresses]
      p.first_name, p.last_name = %w(John Doe)
      p.incomplete_items.must_equal [:email, :phone, :addresses]
      p.email, p.phone, p.addresses = ['john@mail.net', '333222', ['Location1']]
      p.incomplete_items.must_equal []
    end
  end

end
