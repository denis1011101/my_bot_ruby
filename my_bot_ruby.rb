# frozen_string_literal: true

require 'yaml'
require 'faraday'
require 'json'

ENV["TZ"] = 'Asia/Yekaterinburg'
TOKEN = ENV['TOKEN']
FILE = 'common_list.yml'
ADMIN_CHAT_ID = '85611094'

def read_yml; YAML.load_file(FILE).transform_keys!(&:to_sym) end

def shuffle_some_words(count_words = 2, count_phrases = 1)
  shuffle_words = read_yml[:my_english_words].shuffle
  shuffle_phrases = read_yml[:my_english_phrases].shuffle
  shuffle_words[0...count_words] + shuffle_phrases[0...count_phrases]
end

def format_message(words, header: false)
  words.unshift("english words:")
  words[0] = "*#{words[0]}*" if header

  words.flat_map { |x| [x, ''] }.tap(&:pop).join("\n")
end

def send_telegram_message(message, chat_id: ADMIN_CHAT_ID)
  puts 'send telegram message'
  Faraday.get("https://api.telegram.org/bot#{TOKEN}/sendMessage",
              { chat_id: chat_id, text: message, parse_mode: 'Markdown' })
end

def receive_message
  puts 'receive message'
  response = Faraday.get("https://api.telegram.org/bot#{TOKEN}/getupdates")

  return puts 'not messages' if response.nil?

  json = JSON.parse(response.body)

  return puts 'invalid json' unless json['ok']

  # when not messages a long time: my_bot_ruby.rb:44:in `receive_message': undefined method `[]' for nil:NilClass (NoMethodError)

  return puts 'invalid chat' unless json['result'][-1]['message']['from']['id'] == ADMIN_CHAT_ID.to_i

  update_id_now = json['result'][-1]['update_id']
  data = read_yml
  update_id_last = data['update_id']
  return puts 'old message' if update_id_last == update_id_now
  data['update_id'] = update_id_now
  File.write('common_list.yml', YAML.dump(data))

  text_from_message = json['result'][-1]['message']['text']
end

def write_new_word
  receive_message
  data = read_yml
end

def help
  %w[/start /words /stop /write_word /add_note]
end

def validation_user_message?(message)
  message.chat.id == ADMIN_CHAT_ID
end

def valid_send_time?
  Time.now.hour.between?(11, 23) && Time.now.min == 30
end

def start_send_telegram_message
  if valid_send_time?
    send_telegram_message(format_message(shuffle_some_words, header: true))
  else
    puts 'sleep'
  end
end

start_send_telegram_message
receive_message
