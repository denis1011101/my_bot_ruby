# Frozen_string_literal: true

# This class is responsible for reading, creating, updating and deleting data from the yml file.
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

  def create_to_yml(key, value)
    data = read_yml[key]
    data[key] << value
    write_yml(data)
  end

  def update_to_yml(key, value)
    data = read_yml[key]
    data[key] = value
    write_yml(data).dump(data)
  end

  def delete_to_yml(key, value)
    data = read_yml[key]
    data[key] = value
    write_yml(data)
  end
end
