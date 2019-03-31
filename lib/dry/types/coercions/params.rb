require 'bigdecimal'
require 'bigdecimal/util'

module Dry
  module Types
    module Coercions
      module Params
        TRUE_VALUES = %w[1 on On ON t true True TRUE T y yes Yes YES Y].freeze
        FALSE_VALUES = %w[0 off Off OFF f false False FALSE F n no No NO N].freeze
        BOOLEAN_MAP = ::Hash[
          TRUE_VALUES.product([true]) + FALSE_VALUES.product([false])
        ].freeze

        extend Coercions

        # @param [String, Object] input
        # @return [Boolean,Object]
        # @see TRUE_VALUES
        # @see FALSE_VALUES
        def self.to_true(input, &block)
          BOOLEAN_MAP.fetch(input.to_s) do
            CoercionError.handle("#{ input } cannot be coerced to true", &block)
          end
        end

        # @param [String, Object] input
        # @return [Boolean,Object]
        # @see TRUE_VALUES
        # @see FALSE_VALUES
        def self.to_false(input, &block)
          BOOLEAN_MAP.fetch(input.to_s) do
            CoercionError.handle("#{ input } cannot be coerced to false", &block)
          end
        end

        # @param [#to_int, #to_i, Object] input
        # @return [Integer, nil, Object]
        def self.to_int(input, &block)
          if input.is_a? String
            Integer(input, 10)
          else
            Integer(input)
          end
        rescue ArgumentError, TypeError => error
          CoercionError.handle(error, &block)
        end

        # @param [#to_f, Object] input
        # @return [Float, nil, Object]
        def self.to_float(input, &block)
          Float(input)
        rescue ArgumentError, TypeError => error
          CoercionError.handle(error, &block)
        end

        # @param [#to_d, Object] input
        # @return [BigDecimal, nil, Object]
        def self.to_decimal(input, &block)
          result = to_float(input) do
            CoercionError.handle("#{ input } cannot be coerced to decimal", &block)
          end

          input.to_d
        end

        # @param [Array, String, Object] input
        # @return [Array, Object]
        def self.to_ary(input, &block)
          if empty_str?(input)
            []
          elsif input.is_a?(::Array)
            input
          else
            CoercionError.handle("#{ input.inspect } cannot be coerced to array", &block)
          end
        end

        # @param [Hash, String, Object] input
        # @return [Hash, Object]
        def self.to_hash(input, &block)
          if empty_str?(input)
            {}
          elsif input.is_a?(::Hash)
            input
          else
            CoercionError.handle("#{ input.inspect } cannot be coerced to hash", &block)
          end
        end
      end
    end
  end
end
