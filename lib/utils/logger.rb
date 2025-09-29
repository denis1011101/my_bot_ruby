module Utils
  def self.safe_puts(message = nil)
    env = ENV['APP_ENV'].to_s.downcase
    if ENV['GITHUB_ACTIONS'] == 'true' || env != 'production'
      puts message
    end
  end
end
