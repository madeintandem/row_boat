# RowBoat

[![Gem Version](https://badge.fury.io/rb/row_boat.svg)](http://badge.fury.io/rb/row_boat) &nbsp;&nbsp;&nbsp;[![Build Status](https://travis-ci.org/devmynd/row_boat.svg?branch=master)](https://travis-ci.org/devmynd/row_boat)

A simple gem to help you import CSVs into your ActiveRecord models.

[Check out the documentation!](/API.md)

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

## Basic Usage

#### [Full documentation can be found here.](/API.md)

Below we're defining the required methods ([`import_into`](/API.md#import_into) and [`column_mapping`](/API.md#column_mapping)) and a few additional options as well (via [`value_converters`](/API.md#value_converters) and [`options`](/API.md#options)). Checkout [API.md](/API.md) for the full documentation for more :)

```ruby
class ImportProduct
  # required
  def import_into
    Product
  end

  # required
  def column_mapping
    {
      prdct_name: :name,
      dllr_amnt: :price_in_cents,
      desc: :description
    }
  end

  # optional
  def value_converters
    {
      price_in_cents: -> (value) { value * 1000 }
    }
  end

  # optional
  def preprocess_row(row)
    if row[:name] && row[:description] && row[:price]
      row
    else
      nil
    end
  end

  #optional
  def options
    {
      validate: false, # this defaults to `true`
      wrap_in_transaction: false # this defaults to `true`
    }
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

