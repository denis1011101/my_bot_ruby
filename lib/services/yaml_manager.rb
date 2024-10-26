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

  def write_yml(key, value)
    data = read_all_keys_with_values
    data[key] = value
    File.open(file, 'w') { |f| f.write(data.to_yaml) }
  rescue Errno::EACCES
    false
  end

  # Create a new value for a key
  def create_to_yml(key, value)
    data = read_yml(key) || []
    data << value
    write_yml(key, data)
  end

  # Update a value for a key
  def update_to_yml(key, old_value, new_value)
    data = read_yml(key)
    return unless data

    index = data.index(old_value)
    return unless index

    data[index] = new_value
    write_yml(key, data)
  end

  # Delete a value for a key
  def delete_to_yml(key, value)
    data = read_yml(key)
    return unless data

    data.delete(value)
    write_yml(key, data)
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
