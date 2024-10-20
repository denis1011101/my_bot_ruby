require 'nokogiri'
require 'net/http'
require 'uri'

# This class is responsible for parsing data from the site.
class DataParser
  URLS = [
    'https://ru.investing.com/currencies/usd-rub',
    'https://ru.investing.com/indices/mcx'
  ]

  def parse
    results = {}

    URLS.each do |url|
      uri = URI.parse(url)
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)

      data = doc.css('div[data-test="instrument-price-last"]').text.strip
      results[url] = data

      raise "Data is missing for URL: #{url}" if data.empty?
    end

    results
  rescue StandardError => e
    { error: "Failed to parse data: #{e.message}" }
  end
end
