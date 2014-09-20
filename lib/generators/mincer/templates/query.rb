# encoding: utf-8

class <%= class_name %>Query < Mincer::Base
  def build_query(relation, args)
    # Apply your conditions, custom selects, etc. to relation
    relation
  end
end
