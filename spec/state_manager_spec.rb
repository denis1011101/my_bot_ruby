# frozen_string_literal: true

require 'rspec'
require 'fileutils'
require_relative '../lib/services/state_manager'

RSpec.describe StateManager do
  let(:manager) { described_class.new }
  let(:test_state_file) { 'tmp/state.json' }

  before do
    FileUtils.mkdir_p('tmp')
    File.delete(test_state_file) if File.exist?(test_state_file)
  end

  after do
    File.delete(test_state_file) if File.exist?(test_state_file)
  end

  describe '#read' do
    it 'returns nil when state file does not exist' do
      expect(manager.read('update_id')).to be_nil
    end

    it 'returns nil when state file contains invalid JSON' do
      File.write(test_state_file, 'not json')
      expect(manager.read('update_id')).to be_nil
    end

    it 'returns value for existing key' do
      File.write(test_state_file, { 'update_id' => 12345 }.to_json)
      expect(manager.read('update_id')).to eq(12345)
    end

    it 'returns nil for missing key' do
      File.write(test_state_file, { 'other_key' => 'value' }.to_json)
      expect(manager.read('update_id')).to be_nil
    end
  end

  describe '#write' do
    it 'creates state file and writes value' do
      manager.write('update_id', 12345)
      data = JSON.parse(File.read(test_state_file))
      expect(data['update_id']).to eq(12345)
    end

    it 'creates tmp directory if it does not exist' do
      FileUtils.rm_rf('tmp')
      manager.write('update_id', 12345)
      expect(File.exist?(test_state_file)).to be true
    end

    it 'preserves existing keys when writing new key' do
      manager.write('update_id', 12345)
      manager.write('other_key', 'value')
      data = JSON.parse(File.read(test_state_file))
      expect(data['update_id']).to eq(12345)
      expect(data['other_key']).to eq('value')
    end

    it 'overwrites existing key value' do
      manager.write('update_id', 12345)
      manager.write('update_id', 67890)
      data = JSON.parse(File.read(test_state_file))
      expect(data['update_id']).to eq(67890)
    end
  end

  describe '#update' do
    it 'yields current value and saves result' do
      manager.write('list', %w[a b])
      result = manager.update('list') { |current| current + ['c'] }
      expect(result).to eq(%w[a b c])
      data = JSON.parse(File.read(test_state_file))
      expect(data['list']).to eq(%w[a b c])
    end

    it 'yields nil for missing key' do
      result = manager.update('list') { |current| (current || []) + ['a'] }
      expect(result).to eq(['a'])
    end

    it 'preserves other keys' do
      manager.write('other', 'keep')
      manager.update('list') { |_| ['new'] }
      data = JSON.parse(File.read(test_state_file))
      expect(data['other']).to eq('keep')
      expect(data['list']).to eq(['new'])
    end
  end

  describe '#synchronize' do
    it 'yields mutable state and persists changes' do
      result = manager.synchronize do |data|
        data['list'] = ['a']
        :ok
      end

      expect(result).to eq(:ok)
      data = JSON.parse(File.read(test_state_file))
      expect(data['list']).to eq(['a'])
    end

    it 'preserves existing keys while mutating state' do
      manager.write('other', 'keep')

      manager.synchronize do |data|
        data['list'] = ['new']
      end

      data = JSON.parse(File.read(test_state_file))
      expect(data['other']).to eq('keep')
      expect(data['list']).to eq(['new'])
    end
  end
end
