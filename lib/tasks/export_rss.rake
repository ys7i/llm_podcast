require "bundler/setup"
Bundler.require
require "rss"
require "fileutils"
require "dotenv"
Dotenv.load

namespace :podcast do
  desc "RSSフィードとHTMLファイルを生成"
  task export_rss: :environment do
    s3_audio_url = ENV["S3_AUDIO_URL"]
    s3_cover_url = ENV["S3_COVER_URL"]
    github_pages_url = ENV["GITHUB_PAGES_URL"]

    # RSSフィードを生成
    rss = RSS::Maker.make("2.0") do |maker|
      maker.channel.title = "LLM Podcast"
      maker.channel.link = github_pages_url
      maker.channel.description = "AI generated podcast"
      maker.channel.language = "en"
      maker.channel.itunes_author = "ys7i"
      maker.channel.itunes_image = s3_cover_url

      Podcast.where(publish_date: nil).update_all(publish_date: Time.current)

      Podcast.order(id: :asc).each do |podcast|
        next unless podcast.audio_file
        item = maker.items.new_item
        item.title = podcast.title
        item.link = "#{s3_audio_url}/#{podcast.audio_file.key}"
        item.guid.content = "#{s3_audio_url}/#{podcast.audio_file.key}"
        item.description = podcast.description
        item.pubDate = (podcast.publish_date || podcast.created_at).rfc2822
        item.enclosure.url = "#{s3_audio_url}/#{podcast.audio_file.key}"
        item.enclosure.length = podcast.audio_file.byte_size
        item.enclosure.type = "audio/mpeg"
      end
    end

    # HTMLファイルのテンプレート
    html_template = <<~HTML
      <!DOCTYPE html>
      <html lang="ja">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>ys7i LLM Podcast</title>
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

              #{Podcast.order(id: :asc).map do |podcast|
                next unless podcast.audio_file
                publish_date = podcast.publish_date || podcast.created_at
                <<~EPISODE
                  <div class="episode">
                      <h3>🎧 #{podcast.title}</h3>
                      <div class="metadata">
                          <p><strong>公開日:</strong> #{publish_date.strftime('%Y年%m月%d日')}</p>
                          <p><strong>説明:</strong> #{podcast.description}</p>
                      </div>
                      <audio controls class="audio-player">
                          <source src="#{s3_audio_url}/#{podcast.audio_file.key}" type="audio/mpeg">
                          お使いのブラウザは音声再生をサポートしていません。
                      </audio>
                  </div>
                EPISODE
              end.compact.join("\n")}

              <footer style="text-align: center; margin-top: 40px; color: #6a737d; border-top: 1px solid #e1e5e9; padding-top: 20px;">
                  <p>🚀 Powered by GitHub Pages</p>
              </footer>
          </div>
      </body>
      </html>
    HTML

    # docsディレクトリが存在しない場合は作成
    FileUtils.mkdir_p("docs")

    # GitHub Pages用のdocsディレクトリに書き出し
    File.open("docs/rss.xml", "w") { |f| f.write(rss) }
    File.open("docs/index.html", "w") { |f| f.write(html_template) }

    puts "RSSフィードとHTMLファイルを生成しました:"
    puts "- docs/rss.xml"
    puts "- docs/index.html"
  end
end
