# frozen_string_literal: true

require_relative 'message_formatter'
require_relative 'shuffler'

class CommandProcessor
  COMMANDS = {
    word: %w[word w],
    add_note: %w[add_note n],
    write_to_yml: %w[write w],
    send_keys: %w[keys k],
    show: %w[show s],
    help: %w[help h],
    custom_timer: %w[timer t]
  }.freeze

  def initialize(yaml_manager, telegram_bot, message_formatter)
    @yaml_manager = yaml_manager
    @telegram_bot = telegram_bot
    @message_formatter = message_formatter
  end

  def process_command(message)
    command = determine_command(message)
    if command
      Utils.safe_puts "Determined command: #{command}"
      send(command, message)
    else
      Utils.safe_puts "No command determined for message: #{message}"
    end
  end

  private

  def word(_message = nil)
    shuffler = Shuffler.new(@yaml_manager)
    words = shuffler.shuffle_some_words
    Utils.safe_puts "Words: #{words}"
    formatted_message = @message_formatter.format_message(words, header: true)
    @telegram_bot.send_message(formatted_message)
  end

  def determine_command(message)
    COMMANDS.each do |method, commands|
      return method if commands.any? { |command| message.start_with?(command) }
    end
    nil
  end

  def send_keys(_message = nil)
    Utils.safe_puts 'send_keys method called'
    keys = @yaml_manager.all_keys
    Utils.safe_puts "Keys: #{keys}"
    @telegram_bot.send_message(keys)
  end

  def show(message)
    key = extract_key_from_message(message)
    if key
      Utils.safe_puts "show method called for key: #{key}"
      value = @yaml_manager.show(key.to_sym)
      Utils.safe_puts "Value for key #{key}: #{value}"
      @telegram_bot.send_message("Value for key #{key}: #{value}")
    else
      @telegram_bot.send_message('Please provide a key to show its value.')
    end
  end

  def extract_key_from_message(message)
    message.split(' ', 2)[1]
  end

  def help(_message = nil)
    formatted_commands = COMMANDS.map do |key, value|
      "#{key}: <code>#{value.join('</code>, <code>')}</code>"
    end.join("\n")

    @telegram_bot.send_message("Available commands:\n#{formatted_commands}")
  end

  def custom_timer(message)
    number, unit = extract_number_and_unit_from_message(message)
    return unless number

    seconds = convert_to_seconds(number, unit)
    @yaml_manager.write_yml(:custom_timer, seconds)
    check_and_send_message(seconds, "Custom timer message after #{seconds} seconds")
  end

  def extract_number_and_unit_from_message(message)
    match = message.match(/(\d+)([smh]?)/)
    return [match[1].to_i, match[2]] if match

    [nil, nil]
  end

  def convert_to_seconds(number, unit)
    case unit
    when 'm'
      number * 60
    when 'h'
      number * 3600
    else
      number
    end
  end

  def check_and_send_message(seconds, message)
    sleep(seconds)
    @telegram_bot.send_message(message)
    sleep(3)
    @telegram_bot.send_message('Hey! Timer is up! First message after timer')
    sleep(2)
    @telegram_bot.send_message('Hey! Timer is up!!! Last message after timer')
  end
end
