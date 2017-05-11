# frozen_string_literal: true

module ProductCSVs
  FILES_PATH = Pathname.new(File.dirname(__FILE__)).join("files")

  def product_csv_path
    FILES_PATH.join("products.csv")
  end

  def invalid_product_csv_path
    FILES_PATH.join("invalid_products.csv")
  end
end
