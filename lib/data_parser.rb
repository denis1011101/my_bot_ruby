# Frozen_string_literal: true

require 'nokogiri'
require 'net/http'

# This class is responsible for parsing data from the site.
class DataParser
  URL = 'https://www.cbr.ru/'

  def parse
    uri = URI(URL)
    response = Net::HTTP.get(uri)
    doc = Nokogiri::HTML(response)

    usd_rate = doc.css('.currency_table .currency_name:contains("USD") ~ .currency_rate').text
    moex_index = doc.css('.indexes_table .index_name:contains("MOEX") ~ .index_current').text

    { usd_rate:, moex_index: }
  end
end
