require 'rspec'

describe YamlManager do
  let(:test_file) { 'test.yml' }
  let(:manager) { YamlManager.new(test_file) }
  let(:key) { :test_key }
  let(:value) { 'test_value' }

  before do
    File.open(test_file, 'w') { |file| file.write({}.to_yaml) }
  end

  after do
    File.delete(test_file) if File.exist?(test_file)
  end

  describe '#read_yml' do
    it 'reads specific key from the yml file' do
      File.open(test_file, 'w') { |file| file.write({ key => value }.to_yaml) }
      expect(manager.read_yml(key)).to eq(value)
    end

    it 'returns nil if the file does not exist' do
      File.delete(test_file) if File.exist?(test_file)
      expect(manager.read_yml(key)).to be_nil
    end

    it 'returns nil if the key does not exist' do
      expect(manager.read_yml(:non_existent_key)).to be_nil
    end
  end
end
