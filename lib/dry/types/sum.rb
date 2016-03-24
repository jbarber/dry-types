module Dry
  module Types
    class Sum
      include Builder

      attr_reader :left

      attr_reader :right

      def initialize(left, right)
        @left, @right = left, right
      end

      def name
        [left, right].map(&:name).join(' | ')
      end

      def call(input)
        try(input) do |result|
          raise ConstraintError, result
        end.input
      end
      alias_method :[], :call

      def try(input, &block)
        result = left.try(input) do
          right.try(input)
        end

        return result if result.success?

        if block
          yield(result)
        else
          result
        end
      end

      def primitive?(value)
        left.primitive?(value) || right.primitive?(value)
      end

      def valid?(value)
        left.valid?(value) || right.valid?(value)
      end
    end
  end
end