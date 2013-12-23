# Mincer
[![Build Status](https://travis-ci.org/spilin/mincer.png)](https://travis-ci.org/spilin/mincer)
[![Code Climate](https://codeclimate.com/repos/52b775836956801ba7000bdb/badges/ec5d5862e4b89d10695c/gpa.png)](https://codeclimate.com/repos/52b775836956801ba7000bdb/feed)
[![Gem Version](https://badge.fury.io/rb/mincer.png)](http://badge.fury.io/rb/mincer)

Mincer is an ActiveRecord::Relation wrapper that applies usefull features to your queries. It can:
1. Paginate
2. Sort
3. Search
4. Dump to Json(Using postgres >= 9.2)
5. Generate digest(usefull for caching)


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
    
Lets create class EmployeesListQuerie class that will inherit from Mincer::Base, and instantiate it

    class EmployeesListQuerie < Mincer::Base
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
    
    employees = EmployeesListQuerie.new(Employee)

`employees` will delegate all methods, that it can't find on itself, to relation objects. This means you can use
`employess` as you would use any ActiveRecord::Relation object:

    <% employees.each do |employee| %>
        <%= employee.employee_name %>
        <%= employee.company_name %>
    <% end %>
    


Now lets's look what more can we do with this object

### Pagination
Micner supports `kaminari` and `will_paginate`. In order to use pagination you need to include one of them 
to your `Gemfile`. Example of using pagination

    employees = EmployeesListQuerie.new(Employee, {'page' => 2, 'per_page' => 10})
    
By default all `Micner` objects will use pagination, even if no arguments are passed. To set default values for pagination please refer to `kaminari` or `will_paginate` documentation.

To disable pagination you can use class method `skip_pagination!`:

    class EmployeesListQuerie < Mincer::Base
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
