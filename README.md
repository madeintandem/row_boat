# RowBoat

Created by &nbsp;&nbsp;&nbsp; [<img src="https://raw.githubusercontent.com/devmynd/row_boat/master/devmynd-logo.png" alt="DevMynd Logo" />](https://www.devmynd.com/)

[![Gem Version](https://badge.fury.io/rb/row_boat.svg)](http://badge.fury.io/rb/row_boat) &nbsp;&nbsp;&nbsp;[![Build Status](https://travis-ci.org/devmynd/row_boat.svg?branch=master)](https://travis-ci.org/devmynd/row_boat)

A simple gem to help you import CSVs into your ActiveRecord models.

[Check out the documentation!](/API.md#rowboat-api)

It uses [SmarterCSV](https://github.com/tilo/smarter_csv) and [`activerecord-import`](https://github.com/zdennis/activerecord-import) to import database records from your CSVs.

## Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "row_boat", "~> 0.3"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install row_boat

## Basic Usage

#### [Full documentation can be found here.](/API.md#rowboat-api)

Below we're defining the required methods ([`import_into`](/API.md#import_into) and [`column_mapping`](/API.md#column_mapping)) and a few additional options as well (via [`value_converters`](/API.md#value_converters) and [`options`](/API.md#options)). Checkout [API.md](/API.md#rowboat-api) for the full documentation for more details :)

```ruby
class ImportProduct < RowBoat::Base
  # required
  def import_into
    Product # The ActiveRecord class we want to import records into.
  end

  # required
  def column_mapping
    {
      # `:prdct_name` is the downcased and symbolized version
      # of our column header, while `:name` is the attribute
      # of our model we want to receive `:prdct_name`'s value
      prdct_name: :name,
      dllr_amnt: :price_in_cents,
      desc: :description
    }
  end

  # optional
  def value_converters
    {
      # Allows us to change values we want to import
      # before we import them
      price_in_cents: -> (value) { value * 1000 }
    }
  end

  # optional
  def preprocess_row(row)
    if row[:name] && row[:description] && row[:price]
      row
    else
      nil # return nil to skip a row
    end
    # we could also remove some attributes or do any
    # other kind of work we want with the given row.
  end

  #optional
  def options
    {
      # These are additional configurations that
      # are generally passed through to SmarterCSV
      # and activerecord-import
      validate: false, # this defaults to `true`
      wrap_in_transaction: false # this defaults to `true`
    }
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests (run `appraisal install` and `appraisal rake` to run the tests against different combinations of dependencies). You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/devmynd/row_boat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

