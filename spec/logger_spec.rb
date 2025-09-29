require_relative 'spec_helper'

RSpec.describe Utils do
  describe '.safe_puts' do
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

    it 'prints when APP_ENV is not production' do
      ENV['APP_ENV'] = 'development'
      ENV.delete('GITHUB_ACTIONS')
      out = capture_stdout { Utils.safe_puts('hello') }
      expect(out).to include('hello')
    end

    it 'does not print when APP_ENV is production and not in GH Actions' do
      ENV['APP_ENV'] = 'production'
      ENV.delete('GITHUB_ACTIONS')
      out = capture_stdout { Utils.safe_puts('hello') }
      expect(out).to eq('')
    end

    it 'prints in GitHub Actions even if APP_ENV is production' do
      ENV['APP_ENV'] = 'production'
      ENV['GITHUB_ACTIONS'] = 'true'
      out = capture_stdout { Utils.safe_puts('hello') }
      expect(out).to include('hello')
    end
  end
end
