class ArticleTranscriptGenerationJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    return if article.podcast_id.present?

    Rails.logger.info "Starting transcript generation for article #{article.id}"

    ActiveRecord::Base.transaction do
      podcast = create_podcast_for_article(article)

      # transcript fileの作成
      create_transcript_file(podcast, article)

      # 次のjobをキューに追加
      ArticleAudioSynthesisJob.perform_later(article.id)

      Rails.logger.info "Completed transcript generation for article #{article.id}"
    rescue => e
      Rails.logger.error "Failed transcript generation for article #{article.id}: #{e.message}"
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

  def generate_transcript_content(article)
    gemini_client = GeminiClient.new
    gemini_client.generate_podcast_transcript(article.url)
  rescue => e
    Rails.logger.error "Failed to generate transcript with Gemini: #{e.message}"
    # フォールバック: 仮のtranscript
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
end
