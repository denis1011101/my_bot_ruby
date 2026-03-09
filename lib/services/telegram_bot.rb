# frozen_string_literal: true

require 'faraday'
require 'json'
require 'yaml'
require_relative 'yaml_manager'
require_relative 'state_manager'

class TelegramBot
  attr_reader :token, :admin_chat_id, :file, :yaml_manager

  def initialize(token, admin_chat_id, file)
    @token = token
    @admin_chat_id = admin_chat_id
    @file = file
    @yaml_manager = YamlManager.new(file)
    @state_manager = StateManager.new
  end

  def send_message(message)
    Utils.log "send telegram message: #{message}"

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
      Utils.log "Error sending message: #{response.body}"
    else
      Utils.log 'Message sent successfully!'
    end
  end

  def receive_message
    Utils.log 'receive message'
    response = Faraday.get("https://api.telegram.org/bot#{@token}/getupdates")
    return Utils.log 'not messages' if response.nil?

    json = JSON.parse(response.body)
    return Utils.log 'invalid json' unless json['ok']

    return Utils.log 'not message' if json['result'].nil? || json['result'][-1].nil? || json['result'][-1]['message'].nil?

    return Utils.log 'invalid chat' unless json['result'][-1]['message']['from']['id'] == @admin_chat_id.to_i

    chat_id = json['result'][-1]['message']['chat']['id']
    Utils.log "Chat ID: #{chat_id}"

    update_id_now = json['result'][-1]['update_id']
    Utils.log "Update ID: #{update_id_now}"

    current_data = @state_manager.read('update_id')
    Utils.log "Current update ID: #{current_data}"
    Utils.log "New update ID: #{update_id_now}"
    return Utils.log 'old message' if current_data == update_id_now

    @state_manager.write('update_id', update_id_now)
    Utils.log "Updated update ID: #{update_id_now}"

    @text_from_message = json['result'][-1]['message']['text']
    Utils.log "Message text: #{@text_from_message}"
    @text_from_message
  end
end
