require 'spec_helper'
require_relative '../lib/services/data_parser'

RSpec.describe DataParser do
  describe '#parse' do
	before do
    data_parser = DataParser.new
	  @result = data_parser.parse
  end

	it 'returns USD rate' do
	  usd_rate = @result["https://ru.investing.com/currencies/usd-rub"]
	  expect(usd_rate).to match(/\d+,\d+/)
	end

	it 'returns MOEX index' do
	  moex_index = @result["https://ru.investing.com/indices/mcx"]
	  expect(moex_index).to match(/\d+\.\d+,\d+/)
	end
  end
end
