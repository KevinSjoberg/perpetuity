require 'perpetuity/mapper_registry'
require 'perpetuity/mapper'

module Perpetuity
  describe Mapper do
    let(:registry) { MapperRegistry.new}
    let(:mapper_class) { Class.new(Mapper) }
    let(:mapper) { mapper_class.new(registry) }
    subject { mapper }

    it { should be_a Mapper }

    it 'has correct attributes' do
      mapper_class.attribute :name
      mapper_class.attributes.should eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      mapper_class.attributes.should be_empty
    end

    it 'can have embedded attributes' do
      mapper_class.attribute :comments, embedded: true
      mapper_class.attribute_set[:comments].should be_embedded
    end

    it 'registers itself with the mapper registry' do
      mapper_class.map Object, registry
      registry[Object].should be_instance_of mapper_class
    end

    context 'with unserializable embedded attributes' do
      let(:unserializable_object) { 1.to_c }
      let(:serialized_attrs) do
        [ Marshal.dump(unserializable_object) ]
      end

      it 'serializes attributes' do
        object = Object.new
        object.instance_variable_set '@sub_objects', [unserializable_object]
        mapper_class.attribute :sub_objects, embedded: true
        mapper_class.map Object, registry
        data_source = double(:data_source)
        mapper.stub(data_source: data_source)
        data_source.should_receive(:can_serialize?).with(unserializable_object).and_return false

        mapper.serialize(object)['sub_objects'].should eq serialized_attrs
      end
    end
  end
end
