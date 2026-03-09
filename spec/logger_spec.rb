require_relative 'spec_helper'

RSpec.describe Utils do
  describe '.log' do
    around do |example|
      original_env = ENV.to_hash
      example.run
      ENV.replace(original_env)
    end

    def capture_stdout
      old_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end

    it 'prints full message when APP_ENV is development' do
      ENV['APP_ENV'] = 'development'
      out = capture_stdout { Utils.log('hello') }
      expect(out).to include('hello')
    end

    it 'prints full message when APP_ENV is production' do
      ENV['APP_ENV'] = 'production'
      out = capture_stdout { Utils.log('secret') }.strip
      expect(out).to eq('secret')
    end

    it 'prints full message when APP_ENV is not set' do
      ENV.delete('APP_ENV')
      out = capture_stdout { Utils.log('hello') }
      expect(out.strip).to eq('hello')
    end
  end
end
