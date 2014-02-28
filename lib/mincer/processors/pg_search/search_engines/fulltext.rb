module Mincer
  module PgSearch
    module SearchEngines
      class Fulltext < Base

        def conditions
          Arel::Nodes::Grouping.new(
              Arel::Nodes::InfixOperation.new('@@', arel_wrap(tsdocument), arel_wrap(tsquery))
          )
        end

        private

        DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/

        def tsquery_for_term(term)
          sanitized_term = term.gsub(DISALLOWED_TSQUERY_CHARACTERS, ' ')

          term_sql = Arel.sql(normalize(Mincer.connection.quote(sanitized_term)))

          # After this, the SQL expression evaluates to a string containing the term surrounded by single-quotes.
          # If :prefix is true, then the term will also have :* appended to the end.
          terms = ["' ", term_sql, " '", (':*' if options[:prefix])].compact

          tsquery_sql = terms.inject do |memo, term|
            Arel::Nodes::InfixOperation.new('||', memo, term)
          end

          Arel::Nodes::NamedFunction.new(
              'to_tsquery',
              [dictionary, tsquery_sql]
          ).to_sql
        end

        def tsquery
          return "''" if pattern.blank?
          query_terms = pattern.split(' ').compact
          tsquery_terms = query_terms.map { |term| tsquery_for_term(term) }
          tsquery_terms.join(options[:any_word] ? ' || ' : ' && ')
        end

        def tsdocument
          columns.map do |search_column|
            Arel::Nodes::NamedFunction.new('to_tsvector',
                [dictionary, coalesce(Arel.sql(normalize(search_column)))]
            ).to_sql
          end.join(' || ')
        end


        # From http://www.postgresql.org/docs/8.3/static/textsearch-controls.html
        #   0 (the default) ignores the document length
        #   1 divides the rank by 1 + the logarithm of the document length
        #   2 divides the rank by the document length
        #   4 divides the rank by the mean harmonic distance between extents (this is implemented only by ts_rank_cd)
        #   8 divides the rank by the number of unique words in document
        #   16 divides the rank by 1 + the logarithm of the number of unique words in document
        #   32 divides the rank by itself + 1
        # The integer option controls several behaviors, so it is a bit mask: you can specify one or more behaviors
        def normalization
          options[:normalization] || 0
        end

        def tsearch_rank
          "ts_rank((#{tsdocument}), (#{tsquery}), #{normalization})"
        end

        def dictionary
          options[:dictionary] || :simple
        end

        def arel_wrap(sql_string)
          Arel::Nodes::Grouping.new(Arel.sql(sql_string))
        end
      end

    end
  end
end