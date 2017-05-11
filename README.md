# RowBoat

A simple gem to help you import CSVs into your ActiveRecord models.

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

```ruby
class ProductBoat < RowBoat::Base
  # required
  def import_into
    Product
  end

  # required
  def column_mapping
    {
      downcased_csv_column_header: :model_attribute_name,
      another_downcased_csv_column_header: :another_model_attribute_name
    }
  end

  # optional
  def options
    super.merge(validate: false)
  end
end

# Later...

ProductBoat.import(path_to_csv)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/devmynd/row_boat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

