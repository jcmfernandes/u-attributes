# frozen_string_literal: true

module Micro::Attributes
  module Features
    module Accept

      module ClassMethods
      end

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      def attributes_errors
        @__attributes_errors
      end

      def rejected_attributes
        @rejected_attributes ||= attributes_errors.keys
      end

      def accepted_attributes
        @accepted_attributes ||= defined_attributes - rejected_attributes
      end

      def attributes_errors?
        !@__attributes_errors.empty?
      end

      def rejected_attributes?
        attributes_errors?
      end

      def accepted_attributes?
        !rejected_attributes?
      end

      private

        def __call_before_attributes_assign
          @__attributes_errors = {}
        end

        def __attribute_assign(name, initialize_value, attribute_data)
          value_to_assign = FetchValueToAssign.(initialize_value, attribute_data[0])

          value = __attributes[name] = instance_variable_set("@#{name}", value_to_assign)

          requrmt_strategy, requrmt_expected = attribute_data[1]

          __attribute_validate(name, value, requrmt_strategy, requrmt_expected) if requrmt_strategy
        end

        def __attribute_validate(name, value, strategy, expected)
          if strategy == :accept
            return if value.kind_of?(expected)

            @__attributes_errors[name] = "expected to be a kind of #{expected}"
          end

          if strategy == :reject
            return if !value.kind_of?(expected)

            @__attributes_errors[name] = "expected to not be a kind of #{expected}"
          end
        end
    end
  end
end
