class TextToSpeechConverter
  VOICES = %w[en-US-Standard-F en-US-Standard-A].freeze

  def initialize
    @client = Google::Cloud::TextToSpeech.text_to_speech
    @logger = Rails.logger
    @options = {
      language: "en-US",
      encoding: :MP3,
      rate: 1.0,
      pitch: 0.0,
      volume_gain_db: 3.0 # 音量を3dB上げる
    }
  end

  def convert_to_audio(text)
    script = parse_file(text)

    begin
      create_audio(script)
    rescue Google::Cloud::Error => e
      @logger.error "Error: #{e.message}"
      raise e
    end
  end

  def test_single_audio(text)
    @logger.info "Testing single audio generation..."

    request = generate_request(text)

    response = @client.synthesize_speech(request)
    @logger.info "Single audio size: #{response.audio_content.bytesize} bytes"

    response.audio_content
  end

  private

  def generate_request(text)
    {
      input: { text: text },
      voice: {
        language_code: @options[:language],
        name: VOICES[0]
      },
      audio_config: {
        audio_encoding: @options[:encoding],
        speaking_rate: @options[:rate],
        pitch: @options[:pitch],
        volume_gain_db: @options[:volume_gain_db]
      }
    }
  end

  def read_file_text(input_file)
    raise "File '#{input_file}' not found" unless File.exist?(input_file)

    text = File.read(input_file, encoding: "UTF-8").strip
    raise "File #{input_file} is empty" if text.empty?

    text
  end

  def parse_file(text)
    text.split(/\n/).map do |line|
      next unless line.match?(/^[a-zA-Z]+:/)

      speaker, text = line.split(":", 2)
      { speaker: speaker.strip, text: text.strip }
    end.select { |turn| !turn.nil? }
  end

  def speaker_voice_map(script)
    hash = {}
    index = 0
    script.each do |turn|
      if hash[turn[:speaker]].nil?
        hash[turn[:speaker]] = VOICES[index]
        index += 1
      end
    end
    hash
  end

  def create_audio(script)
    audio_segments = []
    @speaker_to_voice = speaker_voice_map(script)
    script.each_with_index do |turn, _index|
      request = generate_request(turn)

      response = @client.synthesize_speech(request)
      audio_segments << response.audio_content
    end
    audio_segments.join
  end

  def generate_request(turn)
    {
      input: { text: turn[:text] },
      voice: {
        language_code: @options[:language],
        name: @speaker_to_voice[turn[:speaker]]
      },
      audio_config: {
        audio_encoding: @options[:encoding],
        speaking_rate: @options[:rate],
        pitch: @options[:pitch]
      }
    }
  end
end
