# frozen_string_literal: true

require 'kind'

module Micro
  module Attributes
    require 'micro/attributes/version'
    require 'micro/attributes/utils'
    require 'micro/attributes/diff'
    require 'micro/attributes/macros'
    require 'micro/attributes/features'

    def self.included(base)
      base.extend(::Micro::Attributes.const_get(:Macros))

      base.class_eval do
        private_class_method :__attributes, :__attribute_reader
        private_class_method :__attribute_assign, :__attributes_data_add
      end

      def base.inherited(subclass)
        subclass.__attributes_set_after_inherit__(self.__attributes_data__)

        subclass.extend ::Micro::Attributes.const_get('Macros::ForSubclasses'.freeze)
      end
    end

    def self.without(*names)
      Features.without(names)
    end

    def self.with(*names)
      Features.with(names)
    end

    def self.with_all_features
      Features.all
    end

    def attribute?(name)
      self.class.attribute?(name)
    end

    def attribute(name)
      return unless attribute?(name)

      value = public_send(name)

      block_given? ? yield(value) : value
    end

    def attribute!(name, &block)
      attribute(name) { |name| return block ? block[name] : name }

      raise NameError, "undefined attribute `#{name}"
    end

    def attributes(*names)
      return __attributes if names.empty?

      names.each_with_object({}) do |name, memo|
        memo[name] = attribute(name) if attribute?(name)
      end
    end

    protected

      def attributes=(arg)
        __attributes_assign(Utils.stringify_hash_keys(arg))
      end

    private

      def __attributes
        @__attributes ||= {}
      end

      FetchValueToAssign = -> (value, default) do
        if default.respond_to?(:call)
          callable = default.is_a?(Proc) ? default : default.method(:call)

          callable.arity > 0 ? callable.call(value) : callable.call
        else
          value.nil? ? default : value
        end
      end

      def __attributes_assign(hash)
        self.class.__attributes_data__.each do |name, default|
          __attribute_assign(name, FetchValueToAssign.(hash[name], default)) if attribute?(name)
        end

        __attributes.freeze
      end

      def __attribute_assign(name, value)
        __attributes[name] = instance_variable_set("@#{name}", value)
      end

      private_constant :FetchValueToAssign
  end
end
