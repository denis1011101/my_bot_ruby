require 'spec_helper'

describe 'TelegramMessage' do
  let(:file) { 'common_list.yml' }
  let(:admin_chat_id) { '85611094' }
  let(:token) { ENV['TOKEN'] }
  let(:response) { { 'ok' => true, 'result' => [{ 'update_id' => 1, 'message' => { 'from' => { 'id' => admin_chat_id.to_i }, 'text' => 'some text' } }] } }
  let(:json) { JSON.parse(response.to_json) }

  before do
    allow(Faraday).to receive(:get).and_return(double(:response, body: response.to_json))
    allow(YAML).to receive(:load_file).and_return({ 'update_id' => 0 })
    allow(File).to receive(:write)
  end

  describe '#read_yml' do
    it 'reads the YAML file and transforms the keys' do
      expect(YAML).to receive(:load_file).with(file).and_return({ 'key' => 'value' })
      read_yml
    end
  end

  describe '#create_to_yml' do
    it 'creates a new key-value pair in the YAML file' do
      expect(YAML).to receive(:load_file).with(file).and_return({ my_english_words: %w[word1 word2 word3] })
      expect(File).to receive(:write).with(file, YAML.dump(my_english_words: %w[word1 word2 word3 word4]))
      create_to_yml(:my_english_words, %w[word4])
    end
  end

  describe '#update_to_yml' do
    it 'updates the value of the given key in the YAML file' do
      expect(YAML).to receive(:load_file).with(file).and_return({ my_english_words: %w[word1 word2 word3] })
      expect(File).to receive(:write).with(file, YAML.dump(my_english_words: %w[word4 word2 word3]))
      update_to_yml(:my_english_words, %w[word4])
    end
  end

  describe '#delete_to_yml' do
    it 'deletes the given key-value pair from the YAML file' do
      expect(YAML).to receive(:load_file).with(file).and_return({ my_english_words: %w[word1 word2 word3] })
      expect(File).to receive(:write).with(file, YAML.dump({}))
      delete_to_yml(:my_english_words)
    end
  end

  describe '#shuffle_some_words' do
    it 'shuffles the words from the YAML file' do
      expect(YAML).to receive(:load_file).with(file).and_return({ my_english_words: %w[word1 word2 word3] })
      expect(shuffle_some_words).to match_array(%w[word1 word2 word3])
    end
  end

  describe '#format_message' do
    it 'formats the message with a header' do
      expect(format_message(%w[word1 word2], header: true)).to eq("*english words:*\n\nword1\n\nword2")
    end

    it 'formats the message without a header' do
      expect(format_message(%w[word1 word2], header: false)).to eq("english words:\n\nword1\n\nword2")
    end
  end

  describe '#send_telegram_message' do
    it 'sends a message to Telegram with the given chat ID and text' do
      expect(Faraday).to receive(:get).with("https://api.telegram.org/bot#{token}/sendMessage", { chat_id: admin_chat_id, text: 'message', parse_mode: 'Markdown' })
      send_telegram_message('message', chat_id: admin_chat_id)
    end
  end

  describe '#receive_message' do
    it 'receives a message from Telegram' do
      expect(Faraday).to receive(:get).with("https://api.telegram.org/bot#{token}/getupdates").and_return(double(:response, body: response.to_json))
      expect(receive_message).to eq('some text')
    end

    it 'returns early if there is no response' do
      allow(Faraday).to receive(:get).and_return(nil)
      expect(receive_message).to be_nil
    end

    it 'returns early if the JSON is invalid' do
      allow(Faraday).to receive(:get).and_return(double(:response, body: 'invalid json'))
      expect(receive_message).to be_nil
    end

    it 'returns early if the chat is invalid' do
      allow(Faraday).to receive(:get).and_return(double(:response, body: { 'ok' => true, 'result' => [{ 'update_id' => 1, 'message' => { 'from' => { 'id' => 123 }, 'text' => 'some text' } }] }.to_json))
      expect(receive_message).to be_nil
    end

    it 'returns early if the message is old' do
      allow(YAML).to receive(:load_file).and_return({ 'update_id' => 1 })
      expect(receive_message).to be_nil
    end
  end

  describe '#write_new_word' do
    it 'writes a new word to the YAML file' do
      expect(File).to receive(:write).with(file, anything)
      write_new_word
    end
  end

  describe '#help' do
    it 'returns the list of commands' do
      expect(help).to eq(%w[/start /words /stop /write_word /add_note])
    end
  end

  describe '#valid_user_message?' do
    it 'returns true if the chat ID is valid' do
      message = double(:message, chat: double(:chat, id: admin_chat_id.to_i))
      expect(valid_user_message?(message)).to be(true)
    end

    it 'returns false if the chat ID is invalid' do
      message = double(:message, chat: double(:chat, id: 123))
      expect(valid_user_message?(message)).to be(false)
    end

    describe '#valid_send_time?' do
      it 'returns true if the current time is between 11:00 and 23:30' do
        allow(Time).to receive(:now).and_return(double(:time, hour: 11, min: 30))
        expect(valid_send_time?).to be(true)
        allow(Time).to receive(:now).and_return(double(:time, hour: 23, min: 30))
        expect(valid_send_time?).to be(true)
      end

      it 'returns false if the current time is outside of the range' do
        allow(Time).to receive(:now).and_return(double(:time, hour: 10, min: 30))
        expect(valid_send_time?).to be(false)

        allow(Time).to receive(:now).and_return(double(:time, hour: 23, min: 31))
        expect(valid_send_time?).to be(false)
      end
    end
  end
end