# frozen_string_literal: true

require 'rspec'
require 'timecop'
require_relative '../lib/services/birthday_checker'

RSpec.describe BirthdayChecker do
  let(:yaml_manager) { double('YamlManager') }
  let(:telegram_bot) { double('TelegramBot') }
  let(:checker) { described_class.new(yaml_manager, telegram_bot) }

  let(:test_birthdays) do
    [
      '15.12.1994 - John Doe',
      '03.02 - Jane Smith',
      '24.12 - Алексей Иванов',
      '26.10.1911 - Тест Пользователь',
      '02.11 - Тест Пользователь 2',
      '31.12 - Новогодний Именинник',
      '01.01 - Новогодний Именинник 2'
    ]
  end

  before do
    allow(yaml_manager).to receive(:read_yml).with(:birthdays).and_return(test_birthdays)
    allow_any_instance_of(BirthdayChecker).to receive(:notification_time?).and_return(true)
  end

  describe '#check_birthdays' do
    context 'when checking at notification time' do
      before do
        allow(Time).to receive(:now).and_return(Time.new(2024, 10, 26, 12, 31))
        allow(telegram_bot).to receive(:send_message).with(any_args)
      end

      it 'sends birthday messages' do
        # Проверяем только количество вызовов
        expect(telegram_bot).to receive(:send_message).at_least(:once)
        checker.check_birthdays
      end

      it 'does not send messages for birthdays outside 7-day window' do
        expect(telegram_bot).not_to receive(:send_message).with(/John Doe/)
        expect(telegram_bot).not_to receive(:send_message).with(/Jane Smith/)
        expect(telegram_bot).not_to receive(:send_message).with(/Алексей Иванов/)
        checker.check_birthdays
      end
    end

    context 'when checking at non-notification time' do
      before do
        allow_any_instance_of(BirthdayChecker).to receive(:notification_time?).and_return(false)
      end

      it 'does not send any messages' do
        expect(telegram_bot).not_to receive(:send_message)
        checker.check_birthdays
      end
    end

    context 'when checking birthdays across year boundary' do
      before do
        allow(Time).to receive(:now).and_return(Time.new(2024, 12, 28, 12, 31))
        allow(telegram_bot).to receive(:send_message).with(any_args)
      end

      it 'identifies birthdays in next year' do
        # Проверяем только количество вызовов
        expect(telegram_bot).to receive(:send_message).at_least(:once)
        checker.check_birthdays
      end
    end
  end

  describe 'Birthday struct' do
    let(:birthday) { BirthdayChecker::Birthday.new('26.10.1994', 'Test Person', 26, 10, 1994) }

    describe '#birthday_in_week?' do
      context 'when birthday is within the next 7 days' do
        before do
          Timecop.freeze(Time.new(2024, 10, 20, 12, 0))
        end

        after { Timecop.return }

        it 'returns true' do
          expect(birthday.birthday_in_week?).to be true
        end
      end

      context 'when birthday is more than 7 days away' do
        before do
          Timecop.freeze(Time.new(2024, 10, 1, 12, 0))
        end

        after { Timecop.return }

        it 'returns false' do
          expect(birthday.birthday_in_week?).to be false
        end
      end

      context 'when checking across year boundary' do
        let(:new_year_birthday) { BirthdayChecker::Birthday.new('01.01', 'New Year Person', 1, 1, nil) }

        before do
          Timecop.freeze(Time.new(2024, 12, 28, 12, 0))
        end

        after { Timecop.return }

        it 'returns true for birthdays in early January' do
          expect(new_year_birthday.birthday_in_week?).to be true
        end
      end
    end
  end

  describe '#year_word_form' do
    let(:checker) { described_class.new(nil, nil) }

    it 'returns correct form for different ages' do
      {
        1 => 'год',
        2 => 'года',
        3 => 'года',
        4 => 'года',
        5 => 'лет',
        10 => 'лет',
        11 => 'лет',
        12 => 'лет',
        13 => 'лет',
        14 => 'лет',
        21 => 'год',
        22 => 'года',
        25 => 'лет',
        111 => 'лет',
        121 => 'год'
      }.each do |age, expected|
        expect(checker.send(:year_word_form, age)).to eq(expected),
          "Expected #{age} to be #{expected}, but got #{checker.send(:year_word_form, age)}"
      end
    end
  end
end
