require "googleauth"
require "faraday"
require "json"
require "unidecode"

class GeminiClient
  def initialize
    @project_id = ENV["GOOGLE_CLOUD_PROJECT_ID"]
    @location = ENV["GOOGLE_CLOUD_LOCATION"] || "us-central1"
    @model = "gemini-2.5-flash"

    # Google Cloud 認証
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV["GOOGLE_APPLICATION_CREDENTIALS"]),
      scope: "https://www.googleapis.com/auth/cloud-platform"
    )

    @client = Faraday.new(
      url: "https://aiplatform.googleapis.com",
      headers: {
        "Content-Type" => "application/json"
      },
      request: {
        timeout: 300,
        open_timeout: 30
      }
    ) do |conn|
      conn.response :logger, Rails.logger
    end
  end

  def generate_podcast_transcript(article_url)
    Rails.logger.info "Generating podcast transcript for URL: #{article_url}"

    # アクセストークンを取得
    token = @authorizer.fetch_access_token!

    # リクエストペイロード
    payload = {
      contents: [
        {
          role: "user",
          parts: [
            {
              text: build_prompt(article_url)
            }
          ]
        }
      ],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192
      }
    }

    # APIエンドポイント
    endpoint = "/v1/projects/#{@project_id}/locations/#{@location}/publishers/google/models/#{@model}:generateContent"

    Rails.logger.info "Sending request to: #{endpoint}"

    response = @client.post(endpoint) do |req|
      req.headers["Authorization"] = "Bearer #{token['access_token']}"
      req.body = payload.to_json
    end

    Rails.logger.info "Response status: #{response.status}"

    if response.success?
      result = JSON.parse(response.body)
      Rails.logger.info "Successfully received response from Gemini API"

      if result["candidates"] && result["candidates"].any?
        content = result["candidates"][0]["content"]["parts"][0]["text"]
        Rails.logger.info "Extracted content length: #{content.length}"
        content.force_encoding("UTF-8")
      else
        raise "No content in Gemini API response"
      end
    else
      error_message = "Gemini API request failed: #{response.status} - #{response.body}"
      Rails.logger.error error_message
      raise error_message
    end
  rescue => e
    Rails.logger.error "Gemini API error: #{e.message}"
    raise e
  end

  private

  def build_prompt(article_url)
    <<~PROMPT
      You are an expert podcast script writer. Please read the article at the following URL and create a conversational podcast script between two people.

      Article URL: #{article_url}

      Requirements:
      - Conversational format between two people
      - Use "Liam:" and "Emma:" to distinguish speakers
      - Do not include any non-conversational elements like "(Intro Music fades in and out)" or similar stage directions
      - Explain the article content in an easy-to-understand way
      - Natural conversation flow
      - Each statement should be 1-2 sentences
      - Total length should be around 10,000 words
      - Language: English

      Please create an engaging podcast script based on the article content.
    PROMPT
  end
end
