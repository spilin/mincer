module Mincer
  module Processors
    module Helpers

      def join_expressions(expressions, join_with)
        case join_with
        when :and then Arel::Nodes::And.new(expressions)
        when :or then expressions.inject { |accumulator, expression| Arel::Nodes::Or.new(accumulator, expression) }
        else expressions.inject { |accumulator, expression| Arel::Nodes::InfixOperation.new(join_with, accumulator, expression) }
        end
      end

    end
  end
end
