module Utils
  def self.safe_puts(message = nil)
    env = ENV['APP_ENV'].to_s.downcase

    return puts(message) if env == 'dev' || env == 'development'

    if env == 'production'
      puts mask_sensitive(message)
    else
      puts message
    end
  end

  def self.mask_sensitive(str)
    return '' if str.nil?
    s = str.to_s

    prefix_len = 2
    suffix_len = 2
    total = s.length

    return '*' * total if total <= prefix_len + suffix_len

    prefix = s[0, prefix_len]
    suffix = s[-suffix_len, suffix_len]
    middle = '*' * (total - prefix_len - suffix_len)
    prefix + middle + suffix
  end
end
