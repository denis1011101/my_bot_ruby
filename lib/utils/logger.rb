module Utils
  def self.safe_Utils.safe_puts(message = nil)
    env = ENV['APP_ENV'].to_s.downcase
    if ENV['GITHUB_ACTIONS'] == 'true' || env != 'production'
      Utils.safe_puts message
    end
  end
end
