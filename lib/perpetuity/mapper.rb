require 'perpetuity/attribute_set'
require 'perpetuity/attribute'
require 'perpetuity/validations'
require 'perpetuity/data_injectable'
require 'perpetuity/dereferencer'
require 'perpetuity/retrieval'

module Perpetuity
  class Mapper
    include DataInjectable
    attr_reader :mapper_registry, :identity_map

    def initialize registry=Perpetuity.mapper_registry
      @mapper_registry = registry
      @identity_map = IdentityMap.new
    end

    def self.map klass, registry=Perpetuity.mapper_registry
      registry[klass] = self
      @mapped_class = klass
    end

    def self.attribute_set
      @attribute_set ||= AttributeSet.new
    end

    def self.attribute name, options = {}
      type = options.fetch(:type) { nil }
      attribute_set << Attribute.new(name, type, options)
    end

    def self.attributes
      attribute_set.map(&:name)
    end

    def self.index attribute, options={}
      data_source.index mapped_class, attribute_set[attribute], options
    end

    def remove_index! index
      data_source.remove_index index
    end

    def indexes
      data_source.indexes(mapped_class)
    end

    def reindex!
      indexes.each { |index| data_source.activate_index! index }
      (data_source.active_indexes(mapped_class) - indexes).reject do |index|
        # TODO: Make this not MongoDB-specific
        index.attribute.name.to_s == '_id'
      end.each do |index|
        data_source.remove_index index
      end
    end

    def attributes
      self.class.attributes
    end

    def delete_all
      data_source.delete_all mapped_class
    end

    def insert object
      raise "#{object} is invalid and cannot be persisted." unless self.class.validations.valid?(object)
      serializable_attributes = serialize(object)
      if o_id = object.instance_exec(&self.class.id)
        serializable_attributes[:id] = o_id
      end

      new_id = data_source.insert mapped_class, serializable_attributes
      give_id_to object, new_id
      new_id
    end

    def self.data_source(configuration=Perpetuity.configuration)
      configuration.data_source
    end

    def count &block
      data_source.count mapped_class, &block
    end

    def any? &block
      count(&block) > 0
    end

    def all? &block
      count(&block) == count
    end

    def one? &block
      count(&block) == 1
    end

    def none? &block
      !any?(&block)
    end

    def first
      retrieve.limit(1).first
    end

    def all
      retrieve
    end

    def select &block
      retrieve data_source.query(&block).to_db
    end

    alias :find_all :select

    def find id=nil, cache_result=true, &block
      if block_given?
        select(&block).first
      else
        cached_value = identity_map[mapped_class, id]
        return cached_value if cached_value

        result = select { |object| object.id == id }.first

        if cache_result and !result.nil?
          identity_map << result
        end

        result
      end
    end

    alias :detect :find

    def reject &block
      retrieve data_source.negate_query(&block).to_db
    end

    def delete object
      id = persisted?(object) ? id_for(object) : object
      data_source.delete id, mapped_class
    end

    def load_association! object, attribute
      objects = Array(object)
      dereferencer = Dereferencer.new(mapper_registry)
      dereferencer.load objects.map { |obj| obj.instance_variable_get("@#{attribute}") }

      objects.each do |obj|
        reference = obj.instance_variable_get("@#{attribute}")
        if reference.is_a? Array
          refs = reference
          real_objects = refs.map { |ref| dereferencer[ref] }
          inject_attribute obj, attribute, real_objects
        else
          inject_attribute obj, attribute, dereferencer[reference]
        end
      end
    end

    def self.id &block
      if block_given?
        @id = block
      else
        @id ||= -> { nil }
      end
    end

    def update object, new_data, update_in_memory = true
      id = object.is_a?(mapped_class) ? id_for(object) : object

      inject_data object, new_data if update_in_memory
      data_source.update mapped_class, id, new_data
    end

    def save object
      update object, serialize(object), false
    end

    def increment object, attribute, count=1
      data_source.increment mapped_class, id_for(object), attribute, count
    rescue Moped::Errors::OperationFailure
      raise ArgumentError.new('Attempted to increment a non-numeric value')
    end

    def decrement object, attribute, count=1
      data_source.increment mapped_class, id_for(object), attribute, -count
    rescue Moped::Errors::OperationFailure
      raise ArgumentError.new('Attempted to decrement a non-numeric value')
    end

    def sample
      all.sample
    end

    def persisted? object
      object.instance_variable_defined?(:@id)
    end

    def id_for object
      object.instance_variable_get(:@id) if persisted?(object)
    end

    def self.validate &block
      validations.instance_exec(&block)
    end

    def self.validations
      @validations ||= ValidationSet.new
    end

    def data_source
      self.class.data_source
    end

    def serialize object
      data_source.serialize(object, self)
    end

    def self.mapped_class
      @mapped_class
    end

    def mapped_class
      self.class.mapped_class
    end

    private

    def retrieve criteria={}
      Perpetuity::Retrieval.new self, criteria
    end
  end
end

