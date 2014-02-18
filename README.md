# Mincer
[![Build Status](https://travis-ci.org/spilin/mincer.png)](https://travis-ci.org/spilin/mincer)
[![Code Climate](https://codeclimate.com/github/spilin/mincer.png)](https://codeclimate.com/github/spilin/mincer)
[![Gem Version](https://badge.fury.io/rb/mincer.png)](http://badge.fury.io/rb/mincer)

Mincer is an ActiveRecord::Relation wrapper that applies usefull features to your queries. It can:

[Paginate](#pagination)
[Sort](#sort)
[Search](#search)
[Dump to Json(Using postgres >= 9.2)](#json)
[Generate digest(usefull for caching)](#digest)


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

Lets create class EmployeesListQuery class that will inherit from Mincer::Base, and instantiate it

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


Now lets's look what more can we do with this object

<a name="pagination"/>
### Pagination
Mincer supports [kaminari](https://github.com/amatsuda/kaminari) and [will_paginate](https://github.com/mislav/will_paginate). In order to use pagination you need to include one of them
in your `Gemfile`. Example of using pagination

    employees = EmployeesListQuery.new(Employee, {'page' => 2, 'per_page' => 10})

By default all `Micner` objects will use pagination, even if no arguments are passed. To set default values for pagination please refer to `kaminari` or `will_paginate` documentation.

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

In this example `li` will receive `class="sorted order_down"` or `class="sorted order_up"` if this attribue was used for search.
Generated url will be enchanced with `sort` and `order` attributes.

<a name="search"/>
### Search

Currently Mincer uses [Textacular](https://github.com/textacular/textacular) for search. This sets alot of restrictions:
1. Works only with postgres
2. You have to include `textacular` to your Gemfile
3. You have to install postgres extension that [Textacular](https://github.com/textacular/textacular) uses for searching.

Example of usage:

    employees = EmployeesListQuery.new(Employee, {'pattern' => 'whatever'})

It will use `simple_search`, and if it will return no entries Mincer will run `fuzzy_search`. For more details on what
is the difference between them, plese look refer to `textacular` github [page](https://github.com/textacular/textacular).

<a name="json"/>
### JSON generation

Mincer allowes you to dump query result to JSON using [Postgres JSON Functions](http://www.postgresql.org/docs/9.3/static/functions-json.html)
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

Digest is very usefull for cache invalidation on your views when you are using custom queries. We will modify a bit example:

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
