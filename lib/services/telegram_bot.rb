# frozen_string_literal: true

require 'faraday'
require 'json'
require 'yaml'
require_relative 'yaml_manager'

class TelegramBot
  attr_reader :token, :admin_chat_id, :file, :yaml_manager

  def initialize(token, admin_chat_id, file)
    @token = token
    @admin_chat_id = admin_chat_id
    @file = file
    @yaml_manager = YamlManager.new(file)
  end

  def send_message(message)
    puts "send telegram message: #{message}"

    response = Faraday.post("https://api.telegram.org/bot#{token}/sendMessage") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        chat_id: admin_chat_id,
        text: message,
        parse_mode: 'html'
      }.to_json
    end

    # Проверка ответа от Telegram API
    if response.status != 200
      puts "Error sending message: #{response.body}"
    else
      puts 'Message sent successfully!'
    end
  end

  def receive_message
    puts 'receive message'
    response = Faraday.get("https://api.telegram.org/bot#{@token}/getupdates")
    return puts 'not messages' if response.nil?

    json = JSON.parse(response.body)
    return puts 'invalid json' unless json['ok']

    return puts 'not message' if json['result'].nil? || json['result'][-1].nil? || json['result'][-1]['message'].nil?

    return puts 'invalid chat' unless json['result'][-1]['message']['from']['id'] == @admin_chat_id.to_i

    chat_id = json['result'][-1]['message']['chat']['id']
    puts "Chat ID: #{chat_id}"

    update_id_now = json['result'][-1]['update_id']
    puts "Update ID: #{update_id_now}"

    current_data = yaml_manager.read_yml(:update_id)
    puts "Current update ID in YAML: #{current_data}"
    puts "New update ID: #{update_id_now}"
    return puts 'old message' if current_data == update_id_now

    yaml_manager.write_yml(:update_id, update_id_now)
    puts "Updated YAML data: #{yaml_manager.read_yml(:update_id)}"

    @text_from_message = json['result'][-1]['message']['text']
    puts "Message text: #{@text_from_message}"
    @text_from_message
  end

  private

  def read_yml
    YAML.load_file(@file).transform_keys!(&:to_sym)
  rescue Errno::ENOENT
    {}
  end
end
