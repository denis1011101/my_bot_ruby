require 'yaml'

class YamlManager
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def read_yml
    YAML.load_file(file).transform_keys!(&:to_sym)
  rescue Errno::ENOENT
    {}
  end

  def write_yml(data)
    File.open(file, 'w') { |file| file.write(data.to_yaml) }
  rescue Errno::EACCES
    false
  end

  # Create a new value for a key
  def create_to_yml(key, value)
    data = read_yml
    data[key] ||= []
    data[key] << value
    write_yml(data)
  end

  # Update a value for a key
  def update_to_yml(key, old_value, new_value)
    data = read_yml
    return unless data[key]

    index = data[key].index(old_value)
    return unless index

    data[key][index] = new_value
    write_yml(data)
  end

  # Delete a value for a key
  def delete_to_yml(key, value)
    data = read_yml
    return unless data[key]

    data[key].delete(value)
    write_yml(data)
  end

  # all keys
  def all_keys
    data = read_yml
    data.keys
  end

  # show value for key
  def show(key)
    data = read_yml
    puts "Data from YAML: #{data}"
    data[key]
  end
end
