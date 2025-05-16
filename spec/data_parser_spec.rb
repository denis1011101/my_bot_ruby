require 'spec_helper'
require_relative '../lib/services/data_parser'

describe '#parse' do
  let(:parser) { DataParser.new }

  it 'returns USD rate' do
    result = parser.parse
    expect(result.values.first).not_to be_nil
  end

  it 'returns MOEX index' do
    result = parser.parse
    expect(result.values.last).not_to be_nil
  end
end
