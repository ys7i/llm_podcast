require 'rails_helper'

RSpec.describe Api::V1::ArticlesController, type: :request do
  let!(:article) { create(:article, url: 'https://example.com') }
  describe 'GET /api/v1/articles' do
    it 'retrieves the list of articles' do
      get "/api/v1/articles"
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)
      expect(res["data"].size).to be 1
      expect(res["data"].first["url"]).to eq('https://example.com')
    end
  end

  describe 'GET /api/v1/articles/:id' do
    let!(:article) { create(:article, url: 'https://example.com') }
    it 'retrieves the article details' do
      get "/api/v1/articles/#{article.id}"
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)
      expect(res["data"]["url"]).to eq('https://example.com')
    end
  end

  describe 'POST /api/v1/podcasts/:podcast_id/articles' do
    it 'creates a new article 1' do
      expect do
        post "/api/v1/articles", params: { url: 'https://example.com' }
      end.to change(Article, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
