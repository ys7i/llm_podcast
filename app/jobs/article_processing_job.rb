class ArticleProcessingJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    # podcast_idを持たないarticleのみ処理
    return if article.podcast_id.present?

    Rails.logger.info "Starting article processing for article #{article.id}"

    # 台本生成ジョブを実行
    ArticleTranscriptGenerationJob.perform_now(article_id)

    Rails.logger.info "Completed article processing for article #{article.id}"
  end
end
