# frozen_string_literal: true

class Shuffler
  def initialize(yaml_manager)
    @yaml_manager = yaml_manager
  end

  def shuffle_some_words(count_words = 2, count_phrases = 1)
    words = @yaml_manager.show(:my_english_words) || []
    phrases = @yaml_manager.show(:my_english_phrases) || []

    shuffle_words = words.shuffle
    shuffle_phrases = phrases.shuffle

    shuffle_words[0...count_words] + shuffle_phrases[0...count_phrases]
  end
end
