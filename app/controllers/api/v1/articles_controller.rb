module Api
  module V1
    class ArticlesController < ApplicationController
      def index
        articles = Article.order(created_at: :desc)

        render json: {
          success: true,
          data: articles,
          meta: {
            total: articles.count
          }
        }
      end

      def show
        article = Article.find(params[:id])
        render json: {
          success: true,
          data: article
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Article not found" }, status: :not_found
      end

      def create
        article = Article.new(article_params)
        if article.save
          ArticleTranscriptGenerationJob.perform_later(article.id)
          render json: {
            success: true,
            data: article
          }, status: :created
        else
          render json: {
            success: false,
            errors: article.errors.full_messages
          }, status: :unprocessable_entity
        end
      end


      def article_params
        params.permit(:url)
      end
    end
  end
end
