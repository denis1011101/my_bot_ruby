# frozen_string_literal: true

require 'yaml'
require 'faraday'
require 'json'

ENV['TZ'] = 'Asia/Yekaterinburg'
TOKEN = ENV['TOKEN']
FILE = 'common_list.yml'
ADMIN_CHAT_ID = '85611094'
TIME_NOW = Time.now

# TODO: refactoring by crud: create, read, update, delete
def read_yml
  YAML.load_file(FILE).transform_keys!(&:to_sym)
end

def create_to_yml(key, value)
  data = read_yml[key]
  data[key] << value
  File.write(FILE, YAML.dump(data))
end

def update_to_yml(key, value)
  data = read_yml[key]
  data[key] = value
  File.write(FILE, YAML.dump(data))
end

def delete_to_yml(key, value)
  data = read_yml[key]
  data[key] = value
  File.write(FILE, YAML.dump(data))
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
  puts 'send telegram message: #{message}'
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

  # may be it's fix

  return puts 'not message' if json['result'][-1]['message'].nil?

  return puts 'invalid chat' unless json['result'][-1]['message']['from']['id'] == ADMIN_CHAT_ID.to_i
  binding.break
  update_id_now = json['result'][-1]['update_id']
  # erorr this
  data = read_yml[:update_id]
  update_id_last = data[:update_id]
  return puts 'old message' if update_id_last == update_id_now

  read_yml[:update_id] = update_id_now
  File.write('common_list.yml', YAML.dump(read_yml))

  @text_from_message = json['result'][-1]['message']['text']
end

def write_to_yml
  # TODO: refactoring regexp ^\/(Write|write)[:]([a-zA-Z\s'`]+)(\b[ ]-[ ])([а-яА-Я\s+]$)
  # return puts 'write break - invalid format' unless @text_from_message =~ /^\/Write:\s*[a-zA-Z\s'`.]+ - [а-яА-Я\s\.?]+$/

  # TODO: replace to ^[Ww]rite:\s*[a-zA-Z]+(\s+[a-zA-Z]+)*\s*(-|–)\s*[а-яА-Я]+(\s+[а-яА-Я]+)*$

  input_validation = lambda do
    return send_telegram_message('invalid message') if @text_from_message.empty? || @text_from_message.nil? ||
                                                       @text_from_message != %r{^/(Write|write): }

    @text_from_message.split(' - ')[0].split.each do |word|
      return send_telegram_message('invalid message') unless word =~ /^[a-zA-Z]+$/
    end
    @text_from_message.split(' - ')[1].split.each do |word|
      return send_telegram_message('invalid message') unless word =~ /^[а-яА-Я]+$/
    end

    true
  end

  return send_telegram_message('invalid message') unless input_validation.call

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
  File.write(FILE, YAML.dump(data))
  send_telegram_message("write done in: #{choose_key.call}")
  puts "write done in: #{choose_key.call}"
end

def help
  puts %w[/start /words /stop /write_word /add_note]
end

def validation_user_message?(message)
  message.chat.id == ADMIN_CHAT_ID
end

def valid_send_time?
  TIME_NOW.hour.between?(11, 23) && TIME_NOW.min == 30
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
  send_telegram_message(text) if TIME_NOW == TIME_NOW + number
end

def mid_timer
  # TODO: move write to yml to another method and rewrite it
  send_telegram_message('mid') if TIME_NOW == TIME_NOW + 60
end

def birthday_today?
  birthdays = read_yml[:birthdays]

  birthdays.each do |birthday|
    date = birthday.split(' - ').first
    name = birthday.split(' - ').last
    day, month, year = date.split('.')

    if day.to_i == TIME_NOW.day && month.to_i == TIME_NOW.month
      age = year.nil? ? 'unknown' : time.year - year.to_i
      send_telegram_message("#{name}'s birthday today! #{age} years old")
    end
  end
end

def listener
  # TODO: use valid_send_time method and add arguments
  birthday_today?
  receive_message

  if @text_from_message.start_with?('/write: ')
    write_to_yml
  elsif @text_from_message.start_with?('/keys')
    send_telegram_message(read_yml.keys.to_s)
  elsif @text_from_message.start_with?('/show')
    show
  elsif @text_from_message.start_with?('/help')
    help
  elsif @text_from_message.start_with?('/send')
    send_telegram_message
  elsif @text_from_message.start_with?('/timer')
    custom_timer
  elsif @text_from_message.start_with?('/mid')
    mid_timer
  else
    send_telegram_message('invalid message')
  end
end

listener
start_send_telegram_message
