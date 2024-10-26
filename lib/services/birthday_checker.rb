# frozen_string_literal: true

# BirthdayChecker class is responsible for checking birthdays and sending notifications about them.
class BirthdayChecker
  NOTIFICATION_TIMES = ['13:30', '15:30', '21:30', '23:30'].freeze
  SECONDS_IN_WEEK = 7 * 24 * 60 * 60

  Birthday = Struct.new(:date, :name, :day, :month, :year) do
    def age
      year ? Time.now.year - year : 'unknown'
    end

    def birthday_date
      @birthday_date ||= Time.new(Time.now.year, month, day)
    end

    def birthday_today?
      day == Time.now.day && month == Time.now.month
    end

    def birthday_in_week?
      today = Time.now
      next_week = today + SECONDS_IN_WEEK

      birthday_this_year = Time.new(today.year, month, day)
      birthday_next_year = Time.new(today.year + 1, month, day)

      [birthday_this_year, birthday_next_year].any? do |date|
        (today.to_date..next_week.to_date).include?(date.to_date)
      end
    end
  end

  def initialize(yaml_manager, telegram_bot)
    @yaml_manager = yaml_manager
    @telegram_bot = telegram_bot
  end

  def check_birthdays
    return unless notification_time?
    return puts 'no birthday' if birthdays.empty?

    birthdays.each do |birthday|
      send_notifications(birthday)
    end
  end

  private

  def notification_time?
    NOTIFICATION_TIMES.include?(Time.now.strftime('%H:%M'))
  end

  def birthdays
    @birthdays ||= parse_birthdays
  end

  def parse_birthdays
    raw_birthdays = @yaml_manager.read_yml(:birthdays) || []
    raw_birthdays.map do |birthday_string|
      date, name = birthday_string.split(' - ')
      day, month, year = date.split('.').map(&:to_i)
      Birthday.new(date, name, day, month, year)
    end
  end

  def send_notifications(birthday)
    if birthday.birthday_today?
      send_today_notification(birthday)
    elsif birthday.birthday_in_week?
      send_weekly_notification(birthday)
    end
  end

  def send_today_notification(birthday)
    @telegram_bot.send_message(
      "🎉 Сегодня день рождения у #{birthday.name}!#{age_message(birthday)}"
    )
  end

  def send_weekly_notification(birthday)
    @telegram_bot.send_message(
      "📅 На этой неделе день рождения у #{birthday.name}!#{age_message(birthday)}"
    )
  end

  def age_message(birthday)
    birthday.age == 'unknown' ? '' : " Исполняется #{birthday.age} #{year_word_form(birthday.age)}!"
  end

  def birthday_age_message(birthday)
    return '' if birthday.age == 'unknown'

    "Исполняется #{birthday.age} #{year_word_form(birthday.age)}!"
  end

  def year_word_form(age)
    return 'лет' if (11..14).include?(age % 100)

    case age % 10
    when 1 then 'год'
    when 2..4 then 'года'
    else 'лет'
    end
  end
end
