# frozen_string_literal: true

require 'fileutils'
require 'json'

class StateManager
  STATE_FILE = 'tmp/state.json'
  LOCK_FILE = 'tmp/state.lock'

  def read(key)
    with_lock do
      data = load_data
      data[key]
    end
  end

  def write(key, value)
    with_lock do
      data = load_data
      data[key] = value
      save_data(data)
    end
  end

  def update(key)
    with_lock do
      data = load_data
      current = data[key]
      new_value = yield current
      data[key] = new_value
      save_data(data)
      new_value
    end
  end

  def synchronize
    with_lock do
      data = load_data
      result = yield data
      save_data(data)
      result
    end
  end

  private

  def with_lock(&block)
    FileUtils.mkdir_p(File.dirname(LOCK_FILE))
    File.open(LOCK_FILE, File::CREAT | File::RDWR) do |f|
      f.flock(File::LOCK_EX)
      block.call
    end
  end

  def load_data
    JSON.parse(File.read(STATE_FILE))
  rescue Errno::ENOENT, JSON::ParserError
    {}
  end

  def save_data(data)
    FileUtils.mkdir_p(File.dirname(STATE_FILE))
    File.write(STATE_FILE, JSON.pretty_generate(data))
  end
end
