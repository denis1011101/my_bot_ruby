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

  describe '#write_yml' do
    it 'writes data to the yml file' do
      manager.write_yml(key, value)
      expect(YAML.load_file(test_file)).to eq({ key => value })
    end
  end

  describe '#create_to_yml' do
    it 'adds a new key-value pair to the yml file' do
      manager.create_to_yml(key, value)
      expect(YAML.load_file(test_file)).to eq({ key => [value] })
    end
  end

  describe '#update_to_yml' do
    it 'updates the value of a key in the yml file' do
      new_value = 'new_test_value'
      manager.create_to_yml(key, value)
      manager.update_to_yml(key, value, new_value)
      expect(YAML.load_file(test_file)).to eq({ key => [new_value] })
    end
  end

  describe '#delete_to_yml' do
    it 'deletes a key-value pair from the yml file' do
      manager.create_to_yml(key, value)
      manager.delete_to_yml(key, value)
      expect(YAML.load_file(test_file)).to eq({ key => [] })
    end
  end
end
