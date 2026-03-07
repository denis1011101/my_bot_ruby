# frozen_string_literal: true

require 'rspec'
require_relative '../lib/services/telegram_bot'

RSpec.describe TelegramBot do
  let(:token) { 'test_token' }
  let(:admin_chat_id) { '123456' }
  let(:file) { 'data/secrets/common_list.yml' }
  let(:bot) { described_class.new(token, admin_chat_id, file) }

  it 'initializes with token, admin_chat_id, and file' do
    expect(bot.token).to eq(token)
    expect(bot.admin_chat_id).to eq(admin_chat_id)
    expect(bot.file).to eq(file)
  end
end
