# frozen_string_literal: true

require_relative 'lib/services/yaml_manager'
require_relative 'lib/services/message_formatter'
require_relative 'lib/services/telegram_bot'
require_relative 'lib/services/command_processor'
require_relative 'lib/services/birthday_checker'
require_relative 'lib/services/shuffler'
require_relative 'lib/utils/logger'
require_relative 'config'

yaml_manager = YamlManager.new(FILE)
message_formatter = MessageFormatter.new
telegram_bot = TelegramBot.new(TOKEN, ADMIN_CHAT_ID, FILE)
command_processor = CommandProcessor.new(yaml_manager, telegram_bot, message_formatter)
birthday_checker = BirthdayChecker.new(yaml_manager, telegram_bot)

def listener(birthday_checker, telegram_bot, command_processor)
  birthday_checker.check_birthdays
  message = telegram_bot.receive_message

  return unless message

  command_processor.process_command(message)
end

def start_send_telegram_message(telegram_bot, message_formatter, yaml_manager)
  if valid_send_time?
    shuffler = Shuffler.new(yaml_manager)
    shuffled_words = shuffler.shuffle_some_words
    telegram_bot.send_message(message_formatter.format_message(shuffled_words, header: true))
  else
    Utils.safe_puts 'sleep'
  end
end

def force_send?
  v = ENV['FORCE_SEND']
  return false if v.nil?
  %w[1 true yes on].include?(v.downcase)
end

def valid_send_time?
  return true if force_send?
  TIME_NOW.hour.between?(11, 23) && TIME_NOW.min.between?(25, 45)
end

listener(birthday_checker, telegram_bot, command_processor)
start_send_telegram_message(telegram_bot, message_formatter, yaml_manager)
