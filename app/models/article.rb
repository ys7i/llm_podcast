class Article < ApplicationRecord
  belongs_to :podcast, optional: true


  validates :url, presence: true, format: { with: URI.regexp(%w[http https]) }

  def extract_content
    # 将来的にWebスクレイピング機能を追加
    # 現在はURLのみを保存
    nil
  end

  def domain
    URI.parse(url).host
  rescue URI::InvalidURIError
    nil
  end

  def processing_status
    return :pending if podcast.nil?
    return :transcript_ready if podcast.transcript_file.attached? && !podcast.audio_file.attached?
    return :audio_ready if podcast.audio_file.attached?
    :pending
  end

  def pending?
    processing_status == :pending
  end

  def transcript_ready?
    processing_status == :transcript_ready
  end

  def audio_ready?
    processing_status == :audio_ready
  end
end
