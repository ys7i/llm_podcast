class ArticleAudioSynthesisJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(article_id)
    article = Article.find(article_id)
    podcast = article.podcast

    return if podcast.nil?
    return if podcast.audio_file.attached?

    Rails.logger.info "Starting audio synthesis for article #{article.id}"

    begin
      synthesize_audio(podcast, article)

      Rails.logger.info "Completed audio synthesis for article #{article.id}"
    rescue => e
      Rails.logger.error "Failed audio synthesis for article #{article.id}: #{e.message}"
      raise e
    end
  end

  private

  def synthesize_audio(podcast, article)
    return unless podcast.transcript_file.attached?

    # transcript fileを一時ファイルにダウンロード
    text = podcast.transcript_file.download
    begin
      converter = TextToSpeechConverter.new
      audio_data = converter.convert_to_audio(text)

      # 音声ファイルをアップロード
      audio_blob = ActiveStorage::Blob.new(
        filename: "podcast_#{podcast.id}.mp3",
        content_type: "audio/mpeg",
        service_name: :audio_file
      )
      audio_blob.key = "#{audio_blob.key}.mp3"
      audio_blob.upload StringIO.new(audio_data)

      podcast.audio_file.attach(audio_blob)
      Rails.logger.info "Created audio file for podcast #{podcast.id}"
    ensure
      temp_file.close
      temp_file.unlink
    end
  end


  def audio_service_name
    Rails.env.test? ? :test_audio_file : :audio_file
  end
end
