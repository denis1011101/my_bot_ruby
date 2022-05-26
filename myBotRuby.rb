FILE = "unknownEnglishWords".freeze

def read_file
  file = File.open(FILE, "r")
  file_data = file.readlines.map(&:chomp)
  file_data = file_data.reject { |c| c.empty? }
  file.close

  file_data
end

def shuffle_and_show_ten_words
  head_by_file = read_file.first
  shuffle_words_without_head = read_file[1..-1].shuffle
  ten_shuffle_words_without_head = shuffle_words_without_head[0..9]
  ten_shuffle_words_with_head = ten_shuffle_words_without_head.unshift(head_by_file)
  ten_shuffle_words_with_head = ten_shuffle_words_with_head.flat_map { |x| [x, ""] }.tap(&:pop)
  puts ten_shuffle_words_with_head
end

shuffle_and_show_ten_words

