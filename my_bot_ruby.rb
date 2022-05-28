# frozen_string_literal: true

require 'telegram/bot'

TOKEN = ENV['TOKEN']
FILE = 'unknownEnglishWords'

def read_file
  file = File.open(FILE, 'r')
  file_data = file.readlines.map(&:chomp)
  file_data = file_data.reject(&:empty?)
  file.close

  file_data
end

def shuffle_and_show_some_words(count_words = 3)
  count_words -= 1
  head_by_file = read_file.first
  shuffle_words_without_head = read_file[1..].shuffle
  some_shuffle_words_ex_head = shuffle_words_without_head[0..count_words]
  some_shuffle_words_with_head = some_shuffle_words_ex_head.unshift(head_by_file)
  some_shuffle_words_with_head.flat_map { |x| [x, ''] }.tap(&:pop)
end

def format_message(some_words)
  some_words[0] = "*#{some_words[0]}*"
  some_words.map { |x| "#{x}\n" }.join
end

def send_telegram_message(chat_id = '85611094', message)
  puts 'send telegram message'
  Faraday.get("https://api.telegram.org/bot#{TOKEN}/sendMessage",
              { chat_id: chat_id, text: message, parse_mode: 'Markdown' })
end

# #<Faraday::Response:0x0000561a4c3d0218>
send_telegram_message(format_message(shuffle_and_show_some_words))

Telegram::Bot::Client.run(TOKEN, logger: Logger.new($stderr)) do |bot|
  bot.logger.info('Bot has been started')
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}, ")
    when 'words'
      bot.api.send_message(chat_id: message.chat.id, text: "let's go")
      bot.api.send_message(chat_id: message.chat.id,
                           text: send_telegram_message(format_message(shuffle_and_show_some_words)))
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end
