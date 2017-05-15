# RowBoat

[![Gem Version](https://badge.fury.io/rb/row_boat.svg)](http://badge.fury.io/rb/row_boat) &nbsp;&nbsp;&nbsp;[![Build Status](https://travis-ci.org/devmynd/row_boat.svg?branch=master)](https://travis-ci.org/devmynd/row_boat)

A simple gem to help you import CSVs into your ActiveRecord models.

It uses [SmarterCSV](https://github.com/tilo/smarter_csv) and [`activerecord-import`](https://github.com/zdennis/activerecord-import) to import database records from your CSVs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "row_boat"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install row_boat

## Usage

### Basic Usage

Just subclass `RowBoat::Base` and define the `import_into` and `column_mapping` methods to get started.

```ruby
class ImportProduct < RowBoat::Base
  def import_into
    Product
  end

  def column_mapping
    {
      downcased_csv_column_header: :model_attribute_name,
      another_downcased_csv_column_header: :another_model_attribute_name
    }
  end
end
```

Then you can just call `ImportProduct.import("path/to/my.csv")`.

### Advanced Usage

```ruby
class ImportProduct < RowBoat::Base
  # required
  def import_into
    Product
  end

  # required
  def column_mapping
    {
      prdct_name: :name,
      price_amnt: :price_in_cents,
      saleby_yy_mm_dd: :expires_at
    }
  end

  # optional
  def options
    # These are the specified defaults.
    {
      chunk_size: 500,
      recursive: true,
      remove_unmapped_keys: true,
      validate: true,
      wrap_in_transaction: true
    }
  end

  # optional
  def preprocess_rows(rows)
    puts "About to import #{rows.size} rows"
    super
  end

  # optional
  def preprocess_row(row)
    price_description = row[:price_in_cents].zero? ? "free" : "cheap"
    row.merge(description: "#{row[:name]} for #{price_description}!")
  end

  # optional
  def value_converters
    {
      expires_at: -> (value) { Date.parse(value) rescue nil },
      # or
      expires_at: :convert_expires_at,
      # or
      expires_at: ObjectImplementingConvertMethod
    }
  end

  def convert_expires_at(value)
    Date.parse(value) rescue nil
  end

  # optional
  def handle_failed_row(row)
    # `row` is an instance of the return value of `import_into`
    puts row.errors.full_messages.join(", ")
  end

  # optional
  def handle_failed_rows(rows)
    puts "Failed to import #{rows.size} rows :("
    super
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/devmynd/row_boat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

