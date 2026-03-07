# frozen_string_literal: true

require 'psych'

class YamlManager
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def read_yml(key)
    read_yml_stream(key)
  rescue Errno::ENOENT
    nil
  end

  # all keys
  def all_keys
    read_all_keys_with_values.keys
  rescue Errno::ENOENT
    []
  end

  # show value for key
  def show(key)
    read_yml(key)
  end

  private

  def read_yml_stream(target_key)
    return nil if target_key.nil?

    data = Psych.safe_load_file(file, permitted_classes: [Symbol])
    data[target_key.to_sym]
  rescue Errno::ENOENT
    nil
  end

  def read_all_keys_with_values
    Psych.safe_load_file(file, permitted_classes: [Symbol])
  rescue Errno::ENOENT
    {}
  end
end
