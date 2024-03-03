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
  write_yml(data).dump(data))
end

def update_to_yml(key, value)
  data = read_yml[key]
  data[key] = value
  write_yml(data).dump(data))
end

def delete_to_yml(key, value)
  data = read_yml[key]
  data[key] = value
  write_yml(data).dump(data))
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
  puts "send telegram message: #{message}"
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

  # may be it's fix

  return puts 'not message' if json['result'].nil? || json['result'][-1].nil? || json['result'][-1]['message'].nil?

  return puts 'invalid chat' unless json['result'][-1]['message']['from']['id'] == ADMIN_CHAT_ID.to_i

  update_id_now = json['result'][-1]['update_id']

  puts read_yml[:update_id]
  puts update_id_now
  return puts 'old message' if read_yml[:update_id] == update_id_now

  # don't work
  read_yml[:update_id] = update_id_now
  puts read_yml[:update_id]
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
  write_yml(data).dump(data))
  send_telegram_message("write done in: #{choose_key.call}")
  puts "write done in: #{choose_key.call}"
end

def help
  puts %w[/start /words /stop /write_word /add_note]
end

def validation_user_message?(message)
  message.chat.id == ADMIN_CHAT_ID
end

def start_send_telegram_message
  if valid_send_time?
    send_telegram_message(format_message(shuffle_some_words, header: true))
  else
    puts 'sleep'
  end
end

def valid_send_time?
  TIME_NOW.hour.between?(11, 23) && TIME_NOW.min == 30
end

def show
  key = @text_from_message.split(' ').last
  send_telegram_message(read_yml[key.to_sym].to_s)
end

def custom_timer(number)
  # TODO: move write to yml to another method and rewrite it
  send_telegram_message(text) if TIME_NOW + number == TIME_NOW
end

def mid_timer
  # TODO: move write to yml to another method and rewrite it
  send_telegram_message('mid') if TIME_NOW + 60 == TIME_NOW
end

def birthday_today
  current_time = Time.now.strftime('%H.%M').to_f
  return puts 'not birthday time or no birthday today' unless [13.30, 15.30, 21.30, 23.30].include?(current_time)

  check_birthdays
end

def check_birthdays
  birthdays = read_yml[:birthdays]

  birthdays.each do |birthday|
    process_birthday(birthday)
  end
end

def process_birthday(birthday)
  date, name = birthday.split(' - ')
  day, month, year = date.split('.')

  return unless birthday_today?(day, month)

  age = year.nil? ? 'unknown' : Time.now.year - year.to_i
  send_telegram_message("#{name}'s birthday today! #{age} years old")
end

def birthday_today?(day, month)
  day.to_i == Time.now.day && month.to_i == Time.now.month
end

def listener
  birthday_today
  message = receive_message

  return unless message

  process_command(message)
end

def process_command(message)
  command = determine_command(message)
  send(command) if command
end

COMMANDS = {
  '/write: ' => :write_to_yml,
  '/keys' => :send_keys,
  '/show' => :show,
  '/help' => :help,
  '/send' => :send_telegram_message,
  '/timer' => :custom_timer,
  '/mid' => :mid_timer
}.freeze

def determine_command(message)
  COMMANDS.each do |command, method|
    return method if message.start_with?(command)
  end
  nil
end

def send_keys
  send_telegram_message(read_yml.keys.to_s)
end

listener
start_send_telegram_message
