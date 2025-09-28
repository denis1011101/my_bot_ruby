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

  # ...existing code...
    def receive_message
      puts 'receive message'
      response = Faraday.get("https://api.telegram.org/bot#{@token}/getupdates")
      if response.nil?
        puts 'no response'
        return nil
      end

      puts "HTTP status: #{response.status}"
      puts "Response body: #{response.body.inspect}"

      json = begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        puts "JSON parse error: #{e.message}"
        return nil
      end

      unless json['ok']
        puts "invalid json: ok=#{json['ok'].inspect}"
        return nil
      end

      results = json['result'] || []
      return puts 'not message' if results.empty?

      last = results[-1]
      msg = last['message']
      return puts 'not message' if msg.nil?

      from_id = msg.dig('from', 'id')
      chat_id = msg.dig('chat', 'id')
      expected = @admin_chat_id.to_i

      if expected == 0
        puts "ADMIN_CHAT_ID is not set or invalid: #{@admin_chat_id.inspect}"
        return nil
      end

      unless from_id == expected || chat_id == expected
        puts "invalid chat: from_id=#{from_id.inspect} chat_id=#{chat_id.inspect} expected=#{expected}"
        return nil
      end

      update_id_now = last['update_id']
      puts "Update ID: #{update_id_now}"

      current_data = yaml_manager.read_yml(:update_id)
      puts "Current update ID in YAML: #{current_data.inspect}"
      return puts 'old message' if current_data == update_id_now

      yaml_manager.write_yml(:update_id, update_id_now)
      puts "Updated YAML data: #{yaml_manager.read_yml(:update_id).inspect}"

      @text_from_message = msg['text']
      puts "Message text: #{@text_from_message.inspect}"
      @text_from_message
    end
  # ...existing code...

  private

  def read_yml
    YAML.load_file(@file).transform_keys!(&:to_sym)
  rescue Errno::ENOENT
    {}
  end
end
