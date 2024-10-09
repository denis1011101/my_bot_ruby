# frozen_string_literal: true

class Shuffler
  def initialize(yaml_manager)
    @yaml_manager = yaml_manager
  end

  def shuffle_some_words(count_words = 2, count_phrases = 1)
    data = @yaml_manager.read_yml
    shuffle_words = data[:my_english_words].shuffle
    shuffle_phrases = data[:my_english_phrases].shuffle

    shuffle_words[0...count_words] + shuffle_phrases[0...count_phrases]
  end
end
