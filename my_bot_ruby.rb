# frozen_string_literal: true

require 'telegram/bot'

TOKEN = ENV['TOKEN']
FILE = 'unknownEnglishWords'
ADMIN_CHAT_ID = '85611094'

def read_file
  file = File.open(FILE, 'r')
  file_data = file.readlines.map(&:chomp)
  file_data = file_data.reject(&:empty?)
  file.close

  file_data
end

def shuffle_some_words(count_words = 3)
  count_words -= 1
  head_by_file = read_file.first
  shuffle_words_without_head = read_file[1..].shuffle
  some_shuffle_words_ex_head = shuffle_words_without_head[0..count_words]
  some_shuffle_words_ex_head.unshift(head_by_file)
end

def format_message(some_words, flag: false)
  some_words[0] = "*#{some_words[0]}*" if flag == true
  some_words.flat_map { |x| [x, ''] }.tap(&:pop).join("\n")
end

def send_telegram_message(message, chat_id = ADMIN_CHAT_ID)
  puts 'send telegram message'
  Faraday.get("https://api.telegram.org/bot#{TOKEN}/sendMessage",
              { chat_id: chat_id, text: message, parse_mode: 'Markdown' })
end

def help
  %w[/start /words /stop /write_word:]
end

def valid_time_for_message?
  Time.now.localtime('+05:00').hour >= 8 && Time.now.localtime('+05:00').hour <= 23
end

def validation_user_message?(message)
  message.chat.id == ADMIN_CHAT_ID
end

Thread.new do # doesn't work for do
  loop do
    puts Time.now
    send_telegram_message(format_message(shuffle_some_words, flag: true)) if valid_time_for_message?
    sleep(3 * 60 * 60) # 3 hours
  end
end

Telegram::Bot::Client.run(TOKEN, logger: Logger.new($stderr)) do |bot|
  bot.logger.info('Bot has been started')
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}, ")
    when '/words'
      bot.api.send_message(chat_id: message.chat.id, text: format_message(shuffle_some_words, flag: true),
                           parse_mode: 'Markdown')
    when '/write_word'
      bot.api.send_message(chat_id: message.chat.id, text: 'write word')
      File.open(FILE, 'a') { |f| f.write("#{message.text}\n") } # move to method
      bot.api.send_message(chat_id: message.chat.id, text: 'write word success')
    when '/add_note'
    when '/help'
      bot.api.send_message(chat_id: message.chat.id, text: format_message(help))
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end
