# Mincer
[![Build Status](https://travis-ci.org/spilin/mincer.png)](https://travis-ci.org/spilin/mincer)
[![Code Climate](https://codeclimate.com/github/spilin/mincer.png)](https://codeclimate.com/github/spilin/mincer)
[![Coverage Status](https://coveralls.io/repos/spilin/mincer/badge.png)](https://coveralls.io/r/spilin/mincer)
[![Gem Version](https://badge.fury.io/rb/mincer.png)](http://badge.fury.io/rb/mincer)

Mincer is an ActiveRecord::Relation wrapper that applies usefull features to your queries. It can:

[Paginate](#pagination)
[Sort](#sort)
[Search](#search)
[Dump to Json(Using postgres >= 9.2)](#json)
[Generate digest(useful for caching)](#digest)


## Installation

Add this line to your application's Gemfile:

    gem 'mincer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mincer

## Usage
Lets assume we have 2 models

    class Employee < ActiveRecord::Base
        belongs_to :company
    end

    class Company < ActiveRecord::Base
        has_many :employees
    end

### Generating custom query

    rails generate mincer:query EmployeesList

Will generate employees_list_query.rb file in /app/queries/ directory

    class EmployeesListQuery < Mincer::Base
      def build_query(relation, args)
        # Apply your conditions, custom selects, etc. to relation
        relation
      end        
    end

It inherits from Mincer::Base. Lets instantiate it

    class EmployeesListQuery < Mincer::Base
        # method should always return relation
        def build_query(relation, args)
            custom_select = <<-SQL
                employees.id,
                employees.full_name as employee_name,
                companies.name as company_name
            SQL
            relation.joins(:company).select(custom_select)
        end
    end

    employees = EmployeesListQuery.new(Employee)

`employees` will delegate all methods, that it can't find on itself, to relation objects. This means you can use
`employees` as you would use any ActiveRecord::Relation object:

    <% employees.each do |employee| %>
        <%= employee.employee_name %>
        <%= employee.company_name %>
    <% end %>


Now lets look what more can we do with this object

<a name="pagination"/>
### Pagination
Mincer supports [kaminari](https://github.com/amatsuda/kaminari) and [will_paginate](https://github.com/mislav/will_paginate).
In order to use pagination you need to include one of them
in your `Gemfile`. Example of using pagination

    employees = EmployeesListQuery.new(Employee, {'page' => 2, 'per_page' => 10})

By default all `Mincer` objects will use pagination, even if no arguments are passed.
To set default values for pagination please refer to `kaminari` or `will_paginate` documentation.

To disable pagination you can use class method `skip_pagination!`:

    class EmployeesListQuery < Mincer::Base
        skip_pagination!

        # method should always return relation
        def build_query(relation, args)
            custom_select = <<-SQL
                employees.id,
                employees.full_name as employee_name,
                companies.name as company_name
            SQL
            relation.joins(:company).select(custom_select)
        end
    end

<a name="sort"/>
### Sorting

Example of using sorting:

    employees = EmployeesListQuery.new(Employee, {'sort' => 'employee_name', 'order' => 'DESC'})

By default all Mincer objects will sort by attribute `id` in `ASC` order. To change defaults you can override
them like this

    class EmployeesListQuery < Mincer::Base
        # method should always return relation
        def build_query(relation, args)
            custom_select = <<-SQL
                employees.id,
                employees.full_name as employee_name,
                companies.name as company_name
            SQL
            relation.joins(:company).select(custom_select)
        end

      def default_sort_attribute
        'employee_name'
      end

      def default_sort_order
        'DESC'
      end
    end

To disable sorting use class method `skip_sorting!` like this:

    class EmployeesListQuery < Mincer::Base
        skip_sorting!

        # method should always return relation
        def build_query(relation, args)
            custom_select = <<-SQL
                employees.id,
                employees.full_name as employee_name,
                companies.name as company_name
            SQL
            relation.joins(:company).select(custom_select)
        end
    end

Mincer will validate `sort` and `order` params and will not allow to sort by attributes that do not exist.
Default white list consists of all attributes from original scope, in our example `Employee.attribute_name`.
You can expand the list by overriding `allowed_sort_attributes` list like this:

    def allowed_sort_attributes
        super + %w{employee_name company_name}
    end
This will allow to sort by all Employee attributes + `employee_name` and `company_name`

Or restrict it like this:

    def allowed_sort_attributes
        %w{employee_name}
    end
in this example sorting allowed only by `employee_name`.

#### ActionView

If you are using Rails or bare ActionView there are few helper methods at your disposal to help generating links
for sorting. Currently there are 2 methods available: `sort_url_for` and `sort_class_for`.

Example of usage in HAML:

    %ul
        %li{ :class => (sort_class_for employees, 'id') }
            = link_to 'ID', sort_url_for(employees, 'id')
        %li{ :class => (sort_class_for employees, 'employee_name') }
            = link_to 'Employee', sort_url_for(employees, 'employee_name')
        %li{ :class => (sort_class_for employees, 'company_name') }
            = link_to 'Company', sort_url_for(employees, 'company_name')

In this example `li` will receive `class="sorted order_down"` or `class="sorted order_up"` if this attribute was used for search.
Generated url will be enhanced with `sort` and `order` attributes.

<a name="search"/>
### Search

Mincer borrowed allot of search logic from [PgSearch](https://github.com/Casecommons/pg_search).
Currently search only works with postgres.

Example of usage:

    employees = EmployeesListQuery.new(Employee, {'pattern' => 'whatever'})

By default search will be performed on all text/string columns of current model. If you want to explicitly set searchable columns or you can do so using `pg_search` method:

    pg_search [{ :columns => %w{employees.full_name companies.name} } ]

By default search will use [unaccent] to ignore accent marks. You can read more about `unaccent` [here](http://www.postgresql.org/docs/current/static/unaccent.html)
You need to enable `unaccent` extension. If you use Rails, please use migration for that:

    enable_extension 'unaccent'

or run `CREATE EXTENSION IF NOT EXISTS unaccent;`

If by any chance you need to disable `unaccent`:

    pg_search [{ :columns => %w{employees.full_name companies.name} }, :ignore_accent => false ]

If you set `any_word` attribute to true - search will return all items containing any word in the search terms.

    pg_search [{ :columns => %w{employees.full_name companies.name} }, :any_word => true ]

If you set `ignore_case` attribute to true - search will ignore case.

    pg_search [{ :columns => %w{employees.full_name companies.name} }, :ignore_case => true ]

If you set `prefix_matching` attribute to true - lexemes in a tsquery can will be labeled with * to specify prefix matching.

    pg_search [{ :columns => %w{employees.full_name companies.name} }, :prefix_matching => true ]

Options like `unaccent`, `any_word`, `ignore_case`, `prefix_matching` can be set to be used only on query or document. In Example if you use specific column that already has unaccented and lowercased text with GIN/GIST index and do not want to additionally use `unaccent` or `ignore_case` functions on that column(because this will cause index not to work) -you can disable those options. Ex.

    pg_search [{ :columns => %w{employees.full_name} }, :ignore_case => {query: true} ]

This way `ignore_case` function will be used only on pattern that you are searching for and not on columns.

If you set `param_name` attribute to any other string - this string will be used to extract search term from params(Default param_name = 'patern').

    pg_search [{ :columns => %w{employees.full_name companies.name} }, :param_name => 's']
    employees = EmployeesListQuery.new(Employee, {'s' => 'whatever'})

There are 3 search engines you can use: `trigram`, `fulltext` and `array`.
You can specify which one to use, along with other options like this:

    pg_search [{ :columns => %w{employees.full_name companies.name}, :engines => [:fulltext, :trigram] ,:ignore_case => true, :threshold => 0.5, :dictionary => :english }]
You can also add several search statements:

    pg_search [
        { :columns => %w{employees.full_name}, :engines => [:fulltext, :trigram] ,:ignore_case => true},
        { :columns => %w{employees.tags}, :engines => [:array] ,:ignore_case => true, :any_word => true, param_name: 'tag'}
    ]

    employees = EmployeesListQuery.new(Employee, {'patern' => 'whatever', 'tag' => 'fired'})
In this Mincer will search for all employees that are fired OR patern matches full_name. You can use additional option `join_with: :and`. To specify that you need only employees whith matching full name and tag

    pg_search [
        { :columns => %w{employees.full_name}, :engines => [:fulltext, :trigram] ,:ignore_case => true},
        { :columns => %w{employees.tags}, :engines => [:array] ,:ignore_case => true, :any_word => true, param_name: 'tag'}
    ], join_with: :and

You can read details on search engines here: [Trigram](http://www.postgresql.org/docs/9.3/static/pgtrgm.html), [Fulltext](http://www.postgresql.org/docs/9.3/static/textsearch.html)

<a name="json"/>
### JSON generation

Mincer allows you to dump query result to JSON using [Postgres JSON Functions](http://www.postgresql.org/docs/9.3/static/functions-json.html)
Didn't had time to do benchmarking, but it's extremely fast.

Pros:

1. Speed
2. No extra dependencies(you don't need any other JSON generators)

Cons:

1. Works only with postgres version >= 9.2
2. If you are using ruby methods to generate some fields - you won't be able to use them in Mincer objects(Carrierwave image_urls, resource urls). You will have to duplicate logic inside postgres select query.

To dump query result to json string you have to call `to_json` on Mincer object:

    EmployeesListQuery.new(Employee).to_json

In our example it will return something like this

    "[{\"id\":1,\"employee_name\":\"John Smith\",\"company_name\":\"Microsoft\"},{\"id\":2,\"employee_name\":\"Jane Smith\",\"company_name\":\"37 Signals\"}]"

In addition you can pass option `root` to `to_json` method if you need to include root to json string:

    EmployeesListQuery.new(Employee).to_json(root: 'employees')
    # returns
    "{\"employees\":[{\"id\":1,\"employee_name\":\"John Smith\",\"company_name\":\"Microsoft\"},{\"id\":2,\"employee_name\":\"Jane Smith\",\"company_name\":\"37 Signals\"}]}"

<a name="digest"/>
### Digest

Digest is very useful for cache invalidation on your views when you are using custom queries. We will modify a bit example:

    class EmployeesListQuery < Mincer::Base
        digest! %w{employee_updated_at company_updated_at}

        def build_query(relation, args)
            custom_select = <<-SQL
                employees.id,
                employees.full_name as employee_name,
                companies.name as company_name,
                employees.updated_at as employee_updated_at,
                companies.updated_at as company_updated_at
            SQL
            relation.joins(:company).select(custom_select)
        end
    end

In this example we will use 2 updated_at timestamps to generate digest. Whenever one of them will change - digest will change also. To get digest you should use method `digest` on Mincer model

    EmployeesListQuery.new(Employee).digest # "\\x20e93b4dc5e029130f3d60d697137934"

To generate digest you need to install extension 'pgcrypto'. If you use Rails, please use migration for that

    enable_extension 'pgcrypto'

or run `CREATE EXTENSION IF NOT EXISTS pgcrypto;`


## TODO

1. Create general configuration for Mincer that would allow to:
    1. Change sort html classes
    2. Change default arguments(sort, order, pattern, page, per_page..)
    3. Disable some processors for all Mincer objects
2. Create rails generators.
3. Add coalescing as option for document


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2013-2014 Alex Krasynskyi

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
