# frozen_string_literal: true

class MessageFormatter
  def format_message(words, header: false)
    words.unshift('english words:')
    words[0] = "<b>#{words[0]}</b>" if header

    words.flat_map { |x| [x, ''] }.tap(&:pop).join("\n")
  end
end
