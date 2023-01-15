# frozen_string_literal: true

require 'yaml'
require 'faraday'
require 'json'

ENV['TZ'] = 'Asia/Yekaterinburg'
TOKEN = ENV['TOKEN']
FILE = 'common_list.yml'
ADMIN_CHAT_ID = '85611094'

# TODO: refactoring by crud: create, read, update, delete
def read_yml
  YAML.load_file(FILE).transform_keys!(&:to_sym) 
end

def shuffle_some_words(count_words = 2, count_phrases = 1)
  shuffle_words = read_yml[:my_english_words].shuffle
  shuffle_phrases = read_yml[:my_english_phrases].shuffle
  shuffle_words[0...count_words] + shuffle_phrases[0...count_phrases]
end

def format_message(words, header: false)
  words.unshift('english words:')
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
  # binding.break
  return puts 'invalid json' unless json['ok']

  # when not messages a long time: my_bot_ruby.rb:44:in `receive_message': undefined method `[]' for nil:NilClass (NoMethodError)

  return puts 'invalid chat' unless json['result'][-1]['message']['from']['id'] == ADMIN_CHAT_ID.to_i

  update_id_now = json['result'][-1]['update_id']
  data = read_yml
  update_id_last = data[:update_id]
  return puts 'old message' if update_id_last == update_id_now

  data[:update_id] = update_id_now
  File.write('common_list.yml', YAML.dump(data))

  @text_from_message = json['result'][-1]['message']['text']
end

def write_to_yml
  # TODO: fix regexp - incorrect if text: W: test -     
  return puts 'write break - invalid format' unless @text_from_message =~ /^[Write|write:]*[a-zA-Z\s'`]* - [а-яА-Я\s]*$/

  @text_from_message.gsub!('write: ', '')

  choose_key = lambda do
    phrase = @text_from_message.split(' - ')[0]
    words = phrase.split(' ')
    words_count = words.length

    english_articles = %w[a an the to of]
    return :my_english_words if words_count == 1
    return :my_english_words if words_count == 2 && english_articles.include?(words.first)
    return :my_english_phrases if words_count >= 2
  end

  return puts 'word already exists' if read_yml[choose_key.call].include?(@text_from_message)

  send_telegram_message("write start: #{@text_from_message}")
  puts "write start: #{@text_from_message}"
  data = read_yml
  data[choose_key.call] << @text_from_message
  File.write('common_list.yml', YAML.dump(data))
  send_telegram_message("write done in: #{choose_key.call}")
  puts "write done in: #{choose_key.call}"
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

def show
  key = @text_from_message.split(' ').last
  send_telegram_message(read_yml[key.to_sym].to_s)
end

def custom_timer
  # TODO: move write to yml to another method and rewrite it
  send_telegram_message(text) if Time.now == Time.now + number
end

def mid_timer
  # TODO: move write to yml to another method and rewrite it
  send_telegram_message('mid') if Time.now == Time.now + 60
end

def listener
  receive_message
  return puts 'not message' if @text_from_message.nil?

  if @text_from_message.start_with?('write: ')
    write_to_yml
  elsif @text_from_message.start_with?('keys')
    send_telegram_message(read_yml.keys.to_s)
  elsif @text_from_message.start_with?('show')
    show
  elsif @text_from_message.start_with?('help')
    help
  elsif @text_from_message.start_with?('send')
    send_telegram_message
  elsif @text_from_message.start_with?('timer')
    custom_timer
  elsif @text_from_message.start_with?('mid')
    mid_timer
  else
    send_telegram_message('invalid message')
  end
end

listener
start_send_telegram_message
