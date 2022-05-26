require 'telegram/bot'

TOKEN = ENV['TOKEN']
FILE = 'unknownEnglishWords'.freeze

def read_file
  file = File.open(FILE, 'r')
  file_data = file.readlines.map(&:chomp)
  file_data = file_data.reject { |c| c.empty? }
  file.close

  file_data
end

def shuffle_and_show_ten_words
  head_by_file = read_file.first
  shuffle_words_without_head = read_file[1..-1].shuffle
  ten_shuffle_words_without_head = shuffle_words_without_head[0..9]
  ten_shuffle_words_with_head = ten_shuffle_words_without_head.unshift(head_by_file)
  ten_shuffle_words_with_head = ten_shuffle_words_with_head.flat_map { |x| [x, ""] }.tap(&:pop)
  
  ten_shuffle_words_with_head
end

Telegram::Bot::Client.run(TOKEN, logger: Logger.new($stderr)) do |bot|
  bot.logger.info('Bot has been started')
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}, ")
    when 'auth'
      bot.api.send_message(chat_id: message.chat.id, text: "let's go")
      bot.api.send_message(chat_id: message.chat.id, text: "#{shuffle_and_show_ten_words}")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end

