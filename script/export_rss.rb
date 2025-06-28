require 'rss'
require 'time'
require 'dotenv'

# .envファイルを読み込み
Dotenv.load

# 環境変数から設定を取得
CLOUDFRONT_DOMAIN = ENV['CLOUDFRONT_DOMAIN'] || "your-cloudfront-domain.cloudfront.net"
S3_BUCKET_NAME = ENV['S3_BUCKET_NAME'] || "your-podcast-bucket"
GITHUB_PAGES_URL = ENV['GITHUB_PAGES_URL'] || "https://ys7i.github.io/llm_podcast/"

# RSSフィードを生成
rss = RSS::Maker.make("2.0") do |maker|
  maker.channel.title = "ys7i private podcast"
  maker.channel.link = GITHUB_PAGES_URL
  maker.channel.description = "AIで作った音声コンテンツを保存"
  maker.channel.language = "ja"
  maker.channel.itunes_author = "ys7i"
  maker.channel.itunes_image = "https://#{CLOUDFRONT_DOMAIN}/cover.jpg"

  # エピソード1
  item = maker.items.new_item
  item.title = "エピソード1"
  item.link = "https://#{CLOUDFRONT_DOMAIN}/episode1.mp3"
  item.guid.content = "https://#{CLOUDFRONT_DOMAIN}/episode1.mp3"
  item.description = "エピソード1の説明"
  item.pubDate = Time.parse("2025-06-26")
  item.enclosure.url = "https://#{CLOUDFRONT_DOMAIN}/episode1.mp3"
  item.enclosure.length = File.size("audio/episode1.mp3")
  item.enclosure.type = "audio/mpeg"

  # 必要に応じて他のエピソードも追加
end

# HTMLファイルのテンプレート
html_template = <<~HTML
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ys7i Private Podcast</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            background-color: #f6f8fa;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .header h1 {
            color: #24292e;
            margin-bottom: 10px;
        }
        .episode {
            border: 1px solid #e1e5e9;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            background: #fafbfc;
        }
        .episode h3 {
            margin-top: 0;
            color: #24292e;
        }
        .rss-link {
            display: inline-block;
            background: #ff6b35;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            margin-top: 20px;
            font-weight: 500;
            transition: background-color 0.2s;
        }
        .rss-link:hover {
            background: #e55a2b;
        }
        .audio-player {
            width: 100%;
            margin-top: 15px;
        }
        .metadata {
            color: #6a737d;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎙️ ys7i Private Podcast</h1>
            <p>AIで作った音声コンテンツを保存</p>
            <a href="rss.xml" class="rss-link">📡 RSSフィードを購読</a>
        </div>

        <div class="episode">
            <h3>🎧 エピソード1</h3>
            <div class="metadata">
                <p><strong>公開日:</strong> 2025年6月26日</p>
                <p><strong>説明:</strong> エピソード1の説明</p>
            </div>
            <audio controls class="audio-player">
                <source src="https://#{CLOUDFRONT_DOMAIN}/episode1.mp3" type="audio/mpeg">
                お使いのブラウザは音声再生をサポートしていません。
            </audio>
        </div>

        <footer style="text-align: center; margin-top: 40px; color: #6a737d; border-top: 1px solid #e1e5e9; padding-top: 20px;">
            <p>🚀 Powered by GitHub Pages + CloudFront</p>
        </footer>
    </div>
</body>
</html>
HTML

# GitHub Pages用のdocsディレクトリに書き出し
File.open("docs/rss.xml", "w") { |f| f.write(rss) }
File.open("docs/index.html", "w") { |f| f.write(html_template) }

puts "RSSフィードとHTMLファイルを生成しました:"
puts "- docs/rss.xml"
puts "- docs/index.html"
puts "CloudFrontドメイン: #{CLOUDFRONT_DOMAIN}"