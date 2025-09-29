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
      today = Time.now
      year = today.year
      date = Time.new(year, month, day)

      # Если день рождения уже прошел в этом году, берем дату на следующий год
      date = Time.new(year + 1, month, day) if date < today

      date
    end

    def days_until_birthday
      today = Time.now.to_date
      bday = birthday_date.to_date
      (bday - today).to_i
    end

    def birthday_today?
      days_until_birthday.zero?
    end

    def birthday_in_week?
      days_until_birthday.between?(1, 7)
    end
  end

  def initialize(yaml_manager, telegram_bot)
    @yaml_manager = yaml_manager
    @telegram_bot = telegram_bot
  end

  def check_birthdays
    return unless notification_time?
    return Utils.safe_puts 'no birthday' if birthdays.empty?

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
    days = birthday.days_until_birthday
    days_word = days_word_form(days)

    @telegram_bot.send_message(
      "📅 Через #{days} #{days_word} день рождения у #{birthday.name}!#{age_message(birthday)}"
    )
  end

  def age_message(birthday)
    birthday.age == 'unknown' ? '' : " Исполняется #{birthday.age} #{year_word_form(birthday.age)}!"
  end

  def days_word_form(days)
    return 'дней' if days >= 5 || (days >= 11 && days <= 19)

    case days % 10
    when 1 then 'день'
    when 2..4 then 'дня'
    else 'дней'
    end
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
