require 'perpetuity/data_injectable'

module Perpetuity
  describe DataInjectable do
    let(:klass) { Class.new }
    let(:object) { klass.new }

    before { klass.extend DataInjectable }

    it 'injects an attribute into an object' do
      klass.inject_attribute object, :a, 1
      object.instance_variable_get(:@a).should eq 1
    end

    it 'injects data into an object' do
      klass.inject_data object, { a: 1, b: 2 }
      object.instance_variable_get(:@a).should eq 1
      object.instance_variable_get(:@b).should eq 2
    end

    it 'injects an id' do
      klass.inject_data object, { id: 1 }
      object.instance_variable_get(:@id).should eq 1
    end

    it 'injects a specified id' do
      klass.give_id_to object, 2
      object.instance_variable_get(:@id).should eq 2
    end
  end
end
