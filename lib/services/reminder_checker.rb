# frozen_string_literal: true

require_relative 'state_manager'

# ReminderChecker checks for reminders that match the current time and sends notifications.
# Supports two reminder lists:
# - weekly: repeats every week, format "thu 13:30 - Text"
# - one_time: triggers once and gets removed, format "02.03.2026 13:30 - Text"
class ReminderChecker
  WEEKLY_KEY = :'reminders-weekly'
  ONE_TIME_KEY = :'reminders-one_time'
  FIRED_STATE_KEY = 'fired_one_time_reminders'

  OneTimeReminder = Struct.new(:raw, :text, :day, :month, :year, :hour, :minute) do
    def time_match?(now)
      return now.day == day && now.month == month && now.year == year if hour.nil? || minute.nil?

      now.day == day && now.month == month && now.year == year &&
        now.hour == hour && now.min == minute
    end
  end

  WeeklyReminder = Struct.new(:raw, :text, :wday, :hour, :minute) do
    def time_match?(now)
      now.wday == wday && now.hour == hour && now.min == minute
    end
  end

  WDAY_ALIASES = {
    '0' => 0, '7' => 0,
    'sun' => 0, 'sunday' => 0, 'вс' => 0, 'воскресенье' => 0,
    '1' => 1, 'mon' => 1, 'monday' => 1, 'пн' => 1, 'понедельник' => 1,
    '2' => 2, 'tue' => 2, 'tues' => 2, 'tuesday' => 2, 'вт' => 2, 'вторник' => 2,
    '3' => 3, 'wed' => 3, 'wednesday' => 3, 'ср' => 3, 'среда' => 3,
    '4' => 4, 'thu' => 4, 'thur' => 4, 'thurs' => 4, 'thursday' => 4, 'чт' => 4, 'четверг' => 4,
    '5' => 5, 'fri' => 5, 'friday' => 5, 'пт' => 5, 'пятница' => 5,
    '6' => 6, 'sat' => 6, 'saturday' => 6, 'сб' => 6, 'суббота' => 6
  }.freeze

  def initialize(yaml_manager, telegram_bot)
    @yaml_manager = yaml_manager
    @telegram_bot = telegram_bot
    @state_manager = StateManager.new
  end

  def check_reminders
    now = Time.now
    reminders_data = normalized_reminders_data
    raw_strings = reminders_data[:one_time]

    one_time_triggered = process_one_time_reminders(raw_strings, now)
    weekly_triggered = parse_weekly_reminders(reminders_data[:weekly]).select { |r| r.time_match?(now) }
    return Utils.safe_puts 'no reminders' if one_time_triggered.empty? && weekly_triggered.empty?

    weekly_triggered.each do |reminder|
      @telegram_bot.send_message("🔔 Напоминание: #{reminder.text}")
    end
  end

  private

  def process_one_time_reminders(raw_strings, now)
    @state_manager.synchronize do |data|
      one_time_reminders = parse_one_time_reminders(raw_strings)
      matching = one_time_reminders.select { |r| r.time_match?(now) }
      fired = ((data[FIRED_STATE_KEY] || []) & raw_strings)
      data[FIRED_STATE_KEY] = fired

      triggered = matching.reject { |r| fired.include?(r.raw) }
      triggered.each do |reminder|
        @telegram_bot.send_message("🔔 Напоминание: #{reminder.text}")
      end

      data[FIRED_STATE_KEY] = fired + triggered.map(&:raw)
      triggered
    end
  end

  def normalized_reminders_data
    weekly = @yaml_manager.read_yml(WEEKLY_KEY) || []
    one_time = @yaml_manager.read_yml(ONE_TIME_KEY) || []

    { weekly: weekly, one_time: one_time }
  end

  def parse_one_time_reminders(raw)
    raw.filter_map { |value| parse_one_time(value) if value }
  end

  def parse_weekly_reminders(raw)
    raw.filter_map { |value| parse_weekly(value) }
  end

  def parse_one_time(reminder_string)
    datetime_str, text = reminder_string.split(' - ', 2)
    return nil unless datetime_str && text

    date_part, time_part = datetime_str.strip.split(' ', 2)
    return nil unless date_part

    day, month, year = parse_date(date_part)
    return nil unless day && month && year

    hour, minute = time_part ? parse_time(time_part) : [nil, nil]
    return nil if time_part && (hour.nil? || minute.nil?)

    OneTimeReminder.new(reminder_string, text, day, month, year, hour, minute)
  rescue NoMethodError
    nil
  end

  def parse_weekly(reminder_string)
    datetime_str, text = reminder_string.split(' - ', 2)
    return nil unless datetime_str && text

    day_part, time_part = datetime_str.strip.split(' ', 2)
    return nil unless day_part && time_part

    wday = parse_wday(day_part)
    hour, minute = parse_time(time_part)
    return nil unless wday && hour && minute

    WeeklyReminder.new(reminder_string, text, wday, hour, minute)
  rescue NoMethodError
    nil
  end

  def parse_wday(day_part)
    WDAY_ALIASES[day_part.strip.downcase]
  end

  def parse_time(time_part)
    hour, minute = time_part.strip.split(':').map(&:to_i)
    return [nil, nil] unless hour && minute

    [hour, minute]
  end

  def parse_date(date_part)
    parts = date_part.split('.').map(&:to_i)
    return parts if parts.length == 3
    return [parts[0], parts[1], Time.now.year] if parts.length == 2

    [nil, nil, nil]
  end
end
