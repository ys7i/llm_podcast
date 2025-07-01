class ArticleAudioSynthesisJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    # podcast_idを持たないarticleのみ処理
    return if article.podcast_id.present?

    Rails.logger.info "Starting audio synthesis for article #{article.id}"

    begin
      # Podcastを作成してarticleに関連付け
      podcast = create_podcast_for_article(article)

      # transcript fileの作成
      create_transcript_file(podcast, article)

      # 音声合成の実行
      synthesize_audio(podcast, article)

      # script_statusをdoneに更新
      article.mark_script_done!

      Rails.logger.info "Completed audio synthesis for article #{article.id}"
    rescue => e
      Rails.logger.error "Failed audio synthesis for article #{article.id}: #{e.message}"
      raise e
    end
  end

  private

  def create_podcast_for_article(article)
    podcast = Podcast.create!(
      title: "Podcast from #{article.domain}",
      description: "Generated podcast content from #{article.url}"
    )

    article.update!(podcast: podcast)
    Rails.logger.info "Created podcast #{podcast.id} for article #{article.id}"

    podcast
  end

  def create_transcript_file(podcast, article)
    # URLからコンテンツを抽出してtranscript fileを作成
    # 現在は仮のtranscript contentを生成
    transcript_content = generate_transcript_content(article)

    # transcript fileをアップロード
    transcript_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(transcript_content),
      filename: "transcript_#{article.id}.txt",
      content_type: "text/plain",
      service_name: transcript_service_name
    )

    podcast.transcript_file.attach(transcript_blob)
    Rails.logger.info "Created transcript file for podcast #{podcast.id}"
  end

  def synthesize_audio(podcast, article)
    return unless podcast.transcript_file.attached?

    # transcript fileを一時ファイルにダウンロード
    temp_file = Tempfile.new([ "transcript_#{article.id}", ".txt" ])
    begin
      temp_file.write(podcast.transcript_file.download)
      temp_file.rewind

      # TextToSpeechConverterで音声合成
      converter = TextToSpeechConverter.new
      audio_data = converter.convert_file(temp_file.path)

      # 音声ファイルをアップロード
      audio_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(audio_data),
        filename: "audio_#{article.id}.mp3",
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

  def generate_transcript_content(article)
    # 将来的にWebスクレイピングで実際のコンテンツを取得
    # 現在は仮のconversation形式のtranscriptを生成
    <<~TRANSCRIPT
      A: Welcome to today's discussion about #{article.domain}.
      B: Thank you for having me. Today we'll be exploring the content from #{article.url}.
      A: This is a fascinating topic. Can you tell us more about the main points?
      B: Based on the article, there are several key insights worth discussing.
      A: That's very interesting. What are the implications for our listeners?
      B: The implications are quite significant and worth considering carefully.
    TRANSCRIPT
  end

  def transcript_service_name
    Rails.env.test? ? :test_transcript : :transcript
  end

  def audio_service_name
    Rails.env.test? ? :test_audio_file : :audio_file
  end
end