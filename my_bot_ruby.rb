# frozen_string_literal: true

require 'telegram/bot'
require 'yaml'

ENV["TZ"] = 'Asia/Yekaterinburg'
TOKEN = ENV['TOKEN']
FILE = 'common_list.yml'
ADMIN_CHAT_ID = '85611094'
READ_YML = Proc.new { YAML.load_file(FILE).transform_keys!(&:to_sym) }

def shuffle_some_words(count_words = 3)
  count_words -= 1
  shuffle_words = READ_YML.call[:my_english_words].shuffle

  shuffle_words[0..count_words]
end

def format_message(some_words, flag: false) # add argument - name list
  some_words.unshift("english words")
  some_words[0] = "*#{some_words[0]}*" if flag == true # first word a header and bold font

  some_words.flat_map { |x| [x, ''] }.tap(&:pop).join("\n")
end

def send_telegram_message(message, chat_id = ADMIN_CHAT_ID)
  puts 'send telegram message'
  Faraday.get("https://api.telegram.org/bot#{TOKEN}/sendMessage",
              { chat_id: chat_id, text: message, parse_mode: 'Markdown' })
end

# def write

# def repeat validation

def help
  %w[/start /words /stop /write_word /add_note]
end

# дописать
def validation_user_message?(message)
  message.chat.id == ADMIN_CHAT_ID
end

def valdation_time?
  Time.now.hour.between?(11, 23)
end

def start_send_telegram_message
  if valdation_time?
    send_telegram_message(format_message(shuffle_some_words, flag: true))
  else
    puts 'sleep'
  end
end

start_send_telegram_message

=begin
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
    when '/show_notes'
    when '/help'
      bot.api.send_message(chat_id: message.chat.id, text: format_message(help))
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end
=end
