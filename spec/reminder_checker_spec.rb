# frozen_string_literal: true

require 'rspec'
require 'timecop'
require_relative '../lib/services/reminder_checker'

RSpec.describe ReminderChecker do
  let(:yaml_manager) { double('YamlManager') }
  let(:telegram_bot) { double('TelegramBot') }
  let(:checker) { described_class.new(yaml_manager, telegram_bot) }
  let(:weekly_key) { :'reminders-weekly' }
  let(:one_time_key) { :'reminders-one_time' }

  let(:test_weekly_reminders) { ['thu 13:30 - Забронировать тренера Артёма на четверг'] }
  let(:test_one_time_reminders) { ['05.03.2026 09:00 - Оплатить интернет'] }

  before do
    allow(yaml_manager).to receive(:read_yml).with(weekly_key).and_return(test_weekly_reminders)
    allow(yaml_manager).to receive(:read_yml).with(one_time_key).and_return(test_one_time_reminders)
    allow(yaml_manager).to receive(:write_yml)
  end

  describe '#check_reminders' do
    context 'when current time matches a weekly reminder' do
      before do
        Timecop.freeze(Time.new(2026, 3, 5, 13, 30))
      end

      after { Timecop.return }

      it 'sends a notification and does not remove weekly reminder' do
        expect(telegram_bot).to receive(:send_message).with('🔔 Напоминание: Забронировать тренера Артёма на четверг')
        expect(yaml_manager).not_to receive(:write_yml)
        checker.check_reminders
      end
    end

    context 'when current time matches a one-time reminder' do
      before do
        Timecop.freeze(Time.new(2026, 3, 5, 9, 0))
      end

      after { Timecop.return }

      it 'sends a notification and removes only one-time reminder' do
        expect(telegram_bot).to receive(:send_message).with('🔔 Напоминание: Оплатить интернет')
        expect(yaml_manager).to receive(:write_yml).with(one_time_key, [])
        checker.check_reminders
      end
    end

    context 'when there are no reminders' do
      before do
        allow(yaml_manager).to receive(:read_yml).with(weekly_key).and_return(nil)
        allow(yaml_manager).to receive(:read_yml).with(one_time_key).and_return(nil)
        Timecop.freeze(Time.new(2026, 3, 5, 13, 30))
      end

      after { Timecop.return }

      it 'does not send any messages' do
        expect(telegram_bot).not_to receive(:send_message)
        checker.check_reminders
      end
    end

    context 'when multiple reminders match the same time' do
      let(:test_weekly_reminders) { ['thu 13:30 - Еженедельное напоминание'] }
      let(:test_one_time_reminders) { ['05.03.2026 13:30 - Одноразовое напоминание'] }

      before do
        Timecop.freeze(Time.new(2026, 3, 5, 13, 30))
      end

      after { Timecop.return }

      it 'sends all matching reminders' do
        expect(telegram_bot).to receive(:send_message).with('🔔 Напоминание: Одноразовое напоминание')
        expect(telegram_bot).to receive(:send_message).with('🔔 Напоминание: Еженедельное напоминание')
        expect(yaml_manager).to receive(:write_yml).with(one_time_key, [])
        checker.check_reminders
      end
    end

    context 'when one-time reminder is in dd.mm format without time' do
      let(:test_weekly_reminders) { [] }
      let(:test_one_time_reminders) { ['03.03 - Отпраивть подарок маме'] }

      before do
        Timecop.freeze(Time.new(2026, 3, 3, 8, 15))
      end

      after { Timecop.return }

      it 'triggers by date and then removes reminder' do
        expect(telegram_bot).to receive(:send_message).with('🔔 Напоминание: Отпраивть подарок маме')
        expect(yaml_manager).to receive(:write_yml).with(one_time_key, [])
        checker.check_reminders
      end
    end
  end

  describe 'OneTimeReminder struct' do
    let(:reminder) { ReminderChecker::OneTimeReminder.new('05.03.2026 13:30 - Test', 'Test', 5, 3, 2026, 13, 30) }

    describe '#time_match?' do
      it 'returns true when time matches exactly' do
        now = Time.new(2026, 3, 5, 13, 30)
        expect(reminder.time_match?(now)).to be true
      end

      it 'returns false when minute differs' do
        now = Time.new(2026, 3, 2, 13, 31)
        expect(reminder.time_match?(now)).to be false
      end

      it 'returns false when date differs' do
        now = Time.new(2026, 3, 3, 13, 30)
        expect(reminder.time_match?(now)).to be false
      end
    end
  end

  describe 'WeeklyReminder struct' do
    let(:reminder) { ReminderChecker::WeeklyReminder.new('thu 13:30 - Test', 'Test', 4, 13, 30) }

    describe '#time_match?' do
      it 'returns true when weekday and time match exactly' do
        now = Time.new(2026, 3, 5, 13, 30)
        expect(reminder.time_match?(now)).to be true
      end

      it 'returns false when weekday differs' do
        now = Time.new(2026, 3, 6, 13, 30)
        expect(reminder.time_match?(now)).to be false
      end
    end
  end
end
