class ArticleAudioSynthesisJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    # podcast_idを持つarticleのみ処理
    return unless article.podcast_id.present?

    Rails.logger.info "Starting audio synthesis for article #{article.id}"

    begin
      podcast = article.podcast

      # 音声合成の実行
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
    temp_file = Tempfile.new([ "transcript_#{article.id}", ".txt" ])
    begin
      text = podcast.transcript_file.download
      converter = TextToSpeechConverter.new
      audio_data = converter.convert_text(text)

      # 音声ファイルをアップロード
      audio_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(audio_data),
        filename: "podcast_#{podcast.id}.mp3",
        content_type: "audio/mpeg",
        service_name: audio_service_name
      )

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
