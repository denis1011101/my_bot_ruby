class BirthdayChecker
  def initialize(yaml_manager, telegram_bot)
    @yaml_manager = yaml_manager
    @telegram_bot = telegram_bot
  end

  def birthday_today
    current_time = Time.now.strftime('%H.%M').to_f
    return puts 'not birthday time or no birthday today' unless [13.30, 15.30, 21.30, 23.30].include?(current_time)

    check_birthdays
  end

  private

  def check_birthdays
    birthdays = @yaml_manager.read_yml[:birthdays]

    birthdays.each do |birthday|
      process_birthday(birthday)
    end
  end

  def process_birthday(birthday)
    date, name = birthday.split(' - ')
    day, month, year = date.split('.')

    return unless birthday_today?(day, month)

    age = year.nil? ? 'unknown' : Time.now.year - year.to_i
    @telegram_bot.send_message("#{name}'s birthday today! #{age} years old")
  end

  def birthday_today?(day, month)
    day.to_i == Time.now.day && month.to_i == Time.now.month
  end
end
