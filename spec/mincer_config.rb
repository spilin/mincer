Mincer.configure do |config|
  config.pg_search do |search|
    #
    search.param_name = 'pattern'

    # Fulltext search engine defaults. http://www.postgresql.org/docs/9.3/static/textsearch.html
    # Available options:
    # ignore_accent - If set to true will ignore accents. Ex.: "Cüåñtô" == "Cuanto". More information: http://www.postgresql.org/docs/current/static/unaccent.html
    # any_word - If set to true, search will return return all items containing any word in the search terms.
    # dictionary - For more information http://www.postgresql.org/docs/current/static/textsearch-dictionaries.html
    search.fulltext_engine = { ignore_accent: true, any_word: false, dictionary: :simple, ignore_case: false }

    # Trigram search engine defaults. http://www.postgresql.org/docs/current/static/pgtrgm.html
    # Available options:
    # ignore_accent - If set to true will ignore accents. Ex.: "Cüåñtô" == "Cuanto". More information: http://www.postgresql.org/docs/current/static/unaccent.html
    # threshold - # http://www.postgresql.org/docs/current/static/pgtrgm.html
    search.trigram_engine = { ignore_accent: true, treshhold: 0.3 }

    # Array search engine defaults. http://www.postgresql.org/docs/current/static/functions-array.html
    # Available options:
    # ignore_accent - If set to true will ignore accents. Ex.: "Cüåñtô" == "Cuanto". More information: http://www.postgresql.org/docs/current/static/unaccent.html
    # any_word - If set to true, search will return return all items containing any word in the search terms.
    search.array_engine = { ignore_accent: true, any_word: true }

    search.engines = [Mincer::PgSearch::SearchEngines::Fulltext, Mincer::PgSearch::SearchEngines::Array, Mincer::PgSearch::SearchEngines::Trigram]
  end

  config.pagination do |pagination|
    pagination.page_param_name = 'page'
    pagination.per_page_param_name = 'per_page'
  end

  config.sorting do |sorting|
    sorting.attribute_param_name = 'sort'
    sorting.order_param_name = 'order'
  end

end