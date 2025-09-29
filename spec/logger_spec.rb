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

    it 'prints full message when APP_ENV is development' do
      ENV['APP_ENV'] = 'development'
      out = capture_stdout { Utils.safe_puts('hello') }
      expect(out).to include('hello')
    end

    it 'prints masked message when APP_ENV is production (not GH Actions)' do
      ENV['APP_ENV'] = 'production'
      out = capture_stdout { Utils.safe_puts('secret') }.strip
      expect(out).not_to eq('secret')
      # mask: two visible chars, stars, two visible chars
      expect(out).to match(/\A..\*+..\z/)
      expect(out.start_with?('se')).to be true
      expect(out.end_with?('et')).to be true
    end

    it 'prints full message in GitHub Actions even if APP_ENV is production' do
      ENV['APP_ENV'] = 'production'
      out = capture_stdout { Utils.safe_puts('hello') }
      expect(out.strip).to eq('he*lo')
    end
  end
end
