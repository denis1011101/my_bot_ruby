# frozen_string_literal: true

require 'rspec'
require_relative '../lib/services/command_processor'

RSpec.describe CommandProcessor do
  let(:yaml_manager) { double('YamlManager') }
  let(:telegram_bot) { double('TelegramBot', send_message: nil) }
  let(:message_formatter) { double('MessageFormatter') }
  let(:processor) { described_class.new(yaml_manager, telegram_bot, message_formatter) }

  describe '#custom_timer' do
    before do
      allow(processor).to receive(:sleep)
    end

    context 'when called without a number' do
      it 'uses default timer of 180 seconds' do
        expect(telegram_bot).to receive(:send_message).with('Custom timer message after 180 seconds')
        allow(telegram_bot).to receive(:send_message)
        processor.process_command('timer')
      end
    end

    context 'when called with seconds' do
      it 'uses the provided number as seconds' do
        expect(telegram_bot).to receive(:send_message).with('Custom timer message after 60 seconds')
        allow(telegram_bot).to receive(:send_message)
        processor.process_command('timer 60')
      end
    end

    context 'when called with minutes unit' do
      it 'converts minutes to seconds' do
        expect(telegram_bot).to receive(:send_message).with('Custom timer message after 300 seconds')
        allow(telegram_bot).to receive(:send_message)
        processor.process_command('t 5m')
      end
    end

    context 'when called with hours unit' do
      it 'converts hours to seconds' do
        expect(telegram_bot).to receive(:send_message).with('Custom timer message after 7200 seconds')
        allow(telegram_bot).to receive(:send_message)
        processor.process_command('t 2h')
      end
    end
  end
end
