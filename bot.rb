# frozen_string_literal: true

require_relative 'lib/yaml_manager'
require_relative 'lib/message_formatter'
require_relative 'lib/telegram_bot'
require_relative 'lib/timer'
require_relative 'config'

yaml_manager = YamlManager.new(FILE)
message_formatter = MessageFormatter.new
telegram_bot = TelegramBot.new(TOKEN, ADMIN_CHAT_ID)
timer = Timer.new

# Здесь вы можете вызывать методы этих классов для выполнения задач вашего приложения.
# Например, вы можете вызвать метод `telegram_bot.send_message` для отправки сообщения в Telegram.
