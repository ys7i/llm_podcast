class Article < ApplicationRecord
  belongs_to :podcast, optional: true

  enum :script_status, { waiting: 0, done: 1 }, default: :waiting

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

  def mark_script_done!
    update!(script_status: :done)
  end

  def script_completed?
    done?
  end
end
