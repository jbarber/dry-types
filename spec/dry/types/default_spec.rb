RSpec.describe Dry::Types::Definition, '#default' do
  context 'with a definition' do
    subject(:type) { Dry::Types['string'].default('foo') }

    it 'returns default value when nil is passed' do
      expect(type[nil]).to eql('foo')
    end

    it 'aliases #[] as #call' do
      expect(type.call(nil)).to eql('foo')
    end

    it 'returns original value when it is not nil' do
      expect(type['bar']).to eql('bar')
    end
  end

  context 'with a constrained type' do
    it 'does not allow a value that is not valid' do
      expect {
        Dry::Types['strict.string'].default(123)
      }.to raise_error(
        Dry::Types::ConstraintError, /123/
      )
    end
  end

  context 'with a callable value' do
    subject(:type) { Dry::Types['time'].default { Time.now } }

    it 'calls the value' do
      expect(type[nil]).to be_instance_of(Time)
    end
  end
end