RSpec.describe Dry::Types::Struct do
  let(:user_type) { Dry::Types["test.user"] }
  let(:root_type) { Dry::Types["test.super_user"] }

  before do
    module Test
      class Address < Dry::Types::Struct
        attribute :city, "strict.string"
        attribute :zipcode, "coercible.string"
      end

      # This abstract user guarantees User preserves schema definition
      class AbstractUser < Dry::Types::Struct
        attribute :name, "coercible.string"
        attribute :age, "coercible.int"
        attribute :address, "test.address"
      end

      class User < AbstractUser
      end

      class SuperUser < User
        attributes(root: 'strict.bool')
      end
    end
  end

  it_behaves_like Dry::Types::Struct do
    subject(:type) { root_type }
  end

  describe '.new' do
    it 'raises StructError when attribute constructor failed' do
      expect {
        user_type[age: {}]
      }.to raise_error(
        Dry::Types::StructError,
        "[Test::User.new] :name is missing in Hash input"
      )

      expect {
        user_type[name: :Jane, age: '21', address: nil]
      }.to raise_error(
        Dry::Types::StructError,
        "[Test::User.new] nil (NilClass) has invalid type for :address"
      )
    end

    it 'passes through values when they are structs already' do
      address = Test::Address.new(city: 'NYC', zipcode: '312')
      user = user_type[name: 'Jane', age: 21, address: address]

      expect(user.address).to be(address)
    end

    it 'creates an empty struct when called without arguments' do
      class Test::Empty < Dry::Types::Struct
        @constructor = Dry::Types['strict.hash'].strict(schema)
      end

      expect { Test::Empty.new }.to_not raise_error
    end
  end

  describe '.attribute' do
    def assert_valid_struct(user)
      expect(user.name).to eql('Jane')
      expect(user.age).to be(21)
      expect(user.address.city).to eql('NYC')
      expect(user.address.zipcode).to eql('123')
    end

    it 'defines attributes for the constructor' do
      user = user_type[
        name: :Jane, age: '21', address: { city: 'NYC', zipcode: 123 }
      ]

      assert_valid_struct(user)
    end

    it 'ignores unknown keys' do
      user = user_type[
        name: :Jane, age: '21', address: { city: 'NYC', zipcode: 123 }, invalid: 'foo'
      ]

      assert_valid_struct(user)
    end

    it 'merges attributes from the parent struct' do
      user = root_type[
        name: :Jane, age: '21', root: true, address: { city: 'NYC', zipcode: 123 }
      ]

      assert_valid_struct(user)

      expect(user.root).to be(true)
    end

    it 'raises error when type is missing' do
      expect {
        class Test::Foo < Dry::Types::Struct
          attribute :bar
        end
      }.to raise_error(ArgumentError)
    end

    it 'raises error when attribute is defined twice' do
      expect {
        class Test::Foo < Dry::Types::Struct
          attribute :bar, 'strict.string'
          attribute :bar, 'strict.string'
        end
      }.to raise_error(
        Dry::Types::RepeatedAttributeError,
        'Attribute :bar has already been defined'
      )
    end

    it 'can be chained' do
      class Test::Foo < Dry::Types::Struct
      end

      Test::Foo
        .attribute(:foo, 'strict.string')
        .attribute(:bar, 'strict.int')

      foo = Test::Foo.new(foo: 'foo', bar: 123)

      expect(foo.foo).to eql('foo')
      expect(foo.bar).to eql(123)
    end
  end

  describe '.inherited' do
    it 'does not register Value' do
      expect { Dry::Types::Struct.inherited(Dry::Types::Value) }
        .to_not change(Dry::Types, :type_keys)
    end
  end

  describe 'with a blank schema' do
    it 'works for blank structs' do
      class Test::Foo < Dry::Types::Struct; end
      expect(Test::Foo.new.to_h).to eql({})
    end
  end

  describe 'with a safe schema' do
    it 'uses :safe constructor when constructor_type is overridden' do
      struct = Class.new(Dry::Types::Struct) do
        constructor_type(:schema)

        attribute :name, Dry::Types['strict.string'].default('Jane')
        attribute :admin, Dry::Types['strict.bool'].default(true)
      end

      expect(struct.new(name: 'Jane').to_h).to eql(name: 'Jane', admin: true)
      expect(struct.new.to_h).to eql(name: 'Jane', admin: true)
    end
  end

  describe '#to_hash' do
    it 'returns hash with attributes' do
      attributes = {
        name: 'Jane', age: 21, address: { city: 'NYC', zipcode: '123' }
      }

      expect(user_type[attributes].to_hash).to eql(attributes)
    end
  end
end
