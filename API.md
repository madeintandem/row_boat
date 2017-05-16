# RowBoat API

This is really more of a summary of what you can do with `RowBoat::Base` since you subclass it to do everything :)

## Contents

- [Basic Usage](#basic-usage)
- [`.import`](#import)
- [`initialize`](#initialize)
- [`import`](#import-1)
- [`import_into`](#import_into)
- [`csv_source`](#csv_source)
- [`column_mapping`](#column_mapping)
- [`preprocess_row`](#preprocess_row)
- [`preprocess_rows`](#preprocess_rows)
- [`options`](#options)
- [`handle_failed_row`](#handle_failed_row)
- [`handle_failed_rows`](#handle_failed_rows)
- [`value_converters`](#value_converters)

## Basic Usage

Just subclass `RowBoat::Base` and define the [`import_into`](#import_into) and [`column_mapping`](#column_mapping) methods to get started (They're the only methods that you're required to implement).

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

## `.import`

### Description
Imports database records form the given CSV-like object. The CSV-like object can be anything that can be passed to [`SmarterCSV.process`](https://github.com/tilo/smarter_csv#documentation) (string paths to files, files, tempfiles, instances of StringIO, etc).

It returns a hash containing

- `:invalid_records` - an array of all records that failed to import since they were invalid. If you've configured the `:validate` option to be `false` it will be an empty array.
- `:total_inserted` - the total number of records inserted into the database.
- `:inserted_ids` - an array of all of the ids of records inserted into the database.

If you want to pass additional information to help import CSVs, *don't override this method*. It just passes through to [`initialize`](#initialize) so override that :)

### Example

#### Basic Use

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
end

ImportProduct.import("path/to/my.csv")
```

#### Advanced Use

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def intitialize(csv_source, my_options)
    super(csv_source)
    @my_options = my_options
  end
end

ImportProduct.import("path/to/my.csv", foo: "bar")
```

## `initialize`

### Description

Makes a new instance with the given CSV-like object. See [`.import`](#import) for more details around when and how to override this method.

## `import`

### Description

The instance method that actually parses and imports the CSV. Generally, you wouldn't call this directly and would instead call [`.import`](#import).

## `import_into`

### Description

It is required that you override this method to return whatever ActiveRecord class you want your CSV imported into.

### Example

#### Basic Use

```ruby
class ImportProduct < RowBoat::Base
  # other required configuration omitted for brevity
  def import_into
    Product
  end
end
```

#### Advanced Use

```ruby
class ImportProduct < RowBoat::Base
  # other required configuration omitted for brevity
  def import_into
    if csv_source.is_a?(String) && csv_source.match(/category/i)
      ProductCategory
    else
      Product
    end
  end
end

ImportProduct.import("path/to/category.csv")
ImportProduct.import("path/to/product.csv")
```


## `csv_source`

### Description

Whatever you originally passed in as the CSV source.

### Example

```ruby
class ImportProduct < RowBoat::Base
  # other required configuration omitted for brevity
  def import_into
    # `csv_source` is available in any of our instance methods
    if csv_source.is_a?(String) && csv_source.match(/category/i)
      ProductCategory
    else
      Product
    end
  end
end

ImportProduct.import("path/to/category.csv")
ImportProduct.import("path/to/product.csv")
```

## `column_mapping`

### Description

It is required that you override this method with a hash that maps columns in your CSV to their preferred names. 

By default
- CSV column names are downcased symbols of what they look like in the CSV.
- CSV columns that are not mapped are ignored when processing the CSV.

If you're familiar with [SmarterCSV](https://github.com/tilo/smarter_csv#documentation), this method essentially defines your `:key_mapping` and with the `:remove_unmapped_keys` setting set to `true`.

You can change these defaults by overriding the `options` method.

### Example

```ruby
class ImportProduct < RowBoat::Base
  # other required configuration omitted for brevity
  def column_mapping
    {
      prdct_nm: :name,
      "price/cost_amnt": :price_in_cents
    }
  end
end
```

## `preprocess_row`

### Description

Implement this method if you need to do some work on the row before the record is inserted/updated.

If you return `nil` from this method, the row will be skipped in the import.

If the work you intend to do with the row only requires changing one attribute, it is recommended that you override [`value_converters`](#value_converters) instead of this.

### Example

```ruby
  class ImportProduct < RowBoat::Base
    # required configuration omitted for brevity
    def preprocess_row(row)
      { default: :value }.merge(row)
    end
    # or...
    def preprocess_row(row)
      if row[:name] && row[:price]
        row
      else
        nil
      end
    end
  end
```

## `preprocess_rows`

### Description

Override this method if you need to do something with a chunk of rows (the chunk size is determined by the `:chunk_size` option in the [`options`](#options) method).

If you need to filter particular rows, it's better to just implement [`preprocess_row`](#preprocess_row) and return `nil` for the rows you want to ignore.

### Example

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def preprocess_rows(rows)
    if skip_batch?(rows)
      super([])
    else
      super
    end
  end

  def skip_batch?(rows)
    # decide whether or not to skip the batch
  end
end
```

## `options`

### Description

Implement this to configure RowBoat, [SmarterCSV](https://github.com/tilo/smarter_csv), and [activerecord-import](https://github.com/zdennis/activerecord-import).

Except for `:wrap_in_transaction`, all options pass through to SmarterCSV and activerecord-import.

`:wrap_in_transaction` simply tells RowBoat whether or not you want your whole import wrapped in a database transaction.

Whatever you define in this method will be merged into the defaults.

  - `:chunk_size` - `500`
  - `:key_mapping` - `column_mapping`
  - `:recursive` - `true`
  - `:remove_unmapped_keys` - `true`
  - `:validate` - `true`
  - `:value_converters` - `csv_value_converters`
  - `:wrap_in_transaction` - `true`

Don't provide `value_converters` or `key_mapping` options here. Implement the [`value_converters`](#value_converters) and [`column_mapping`](#column_mapping) respectively.

### Example

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def options
    {
      chunk_size: 1000,
      validate: false,
      wrap_in_transaction: false
    }
  end
end
```

## `handle_failed_row`

### Description

Implement this to do some work with a row that has failed to import. 

It's important to note that
- This happens after the import has completed.
- The given row is an instance of whatever class was returned by [`import_into`](#import_into).

These records are also available in the return value of [`.import`](#import).

### Example

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def handle_failed_row(row)
    puts row.errors.full_messages.join(", ")
  end
end
```

## `handle_failed_rows`

### Description

Override this method to do some work will all of the rows that failed to import.

### Example

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def handle_failed_rows(rows)
    puts "Failed to import #{rows.size} rows :("
    super
  end
end
```

## `value_converters`

### Description

Implement to specify how to transalte values from the CSV into whatever sorts of objects you need. 

Simply return a hash that has the mapped column name (ie, what you mapped it to in the [`column_mapping`](#column_mapping) method) as a key pointing to either
- a method name as a symbol
- a proc or lambda
- an object that implements `convert`

Regardless of which one you choose, it take a value and return a converted value.

This is essentially a sugared up version of `:value_converters` option in [SmarterCSV](https://github.com/tilo/smarter_csv#documentation).

### Example

```ruby
class ImportProduct < RowBoat::Base
  # required configuration omitted for brevity
  def value_converters
    {
      sell_by: :convert_date,
      name: -> (value) { value.titlelize },
      price: proc { |value| value.to_i }
      description: DescriptionConverter
    }
  end

  def convert_date(value)
    Date.parse(value) rescue nil
  end
end

module DescriptionConverter
  def self.convert(value)
    value.present? ? value : "default description :("
  end
end
```
