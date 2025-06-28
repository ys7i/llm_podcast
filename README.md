# ys7i Private Podcast

AI で作った音声コンテンツを保存するプライベートポッドキャストです。

## 構成

- **GitHub Pages**: RSS フィードとポッドキャスト情報ページの配信
- **S3 + CloudFront**: 音声ファイル（MP3）の CDN 配信
- **GitHub Actions**: 自動デプロイ

## セットアップ手順

### 1. 依存関係のインストール

```bash
# Rubyの依存関係をインストール
bundle install
```

### 2. 環境変数の設定

`.env`ファイルを作成して以下の内容を設定してください：

```bash
# CloudFront設定
CLOUDFRONT_DOMAIN=your-cloudfront-domain.cloudfront.net
S3_BUCKET_NAME=your-podcast-bucket

# GitHub Pages設定
GITHUB_PAGES_URL=https://ys7i.github.io/llm_podcast/
```

### 3. S3 バケットと CloudFront の設定

1. **S3 バケットを作成**

   ```bash
   # AWS CLIでバケットを作成
   aws s3 mb s3://your-podcast-bucket

   # 音声ファイルをアップロード
   aws s3 cp audio/episode1.mp3 s3://your-podcast-bucket/
   ```

2. **CloudFront ディストリビューションを作成**
   - S3 バケットをオリジンとして設定
   - カスタムドメインを設定（オプション）

### 4. GitHub Pages の設定

1. GitHub リポジトリの設定ページに移動
2. **Pages**セクションで以下を設定：
   - **Source**: Deploy from a branch
   - **Branch**: main
   - **Folder**: /docs

### 5. GitHub Secrets の設定

GitHub リポジトリの **Settings** → **Secrets and variables** → **Actions** で以下のシークレットを設定：

- `CLOUDFRONT_DOMAIN`: CloudFront ドメイン
- `S3_BUCKET_NAME`: S3 バケット名
- `GITHUB_PAGES_URL`: GitHub Pages URL

### 6. デプロイ

```bash
# RSSを生成してデプロイ
ruby script/export_rss.rb
git add .
git commit -m "Update RSS feed"
git push origin main
```

## ファイル構造

```
llm_podcast/
├── audio/                 # 音声ファイル
│   └── episode1.mp3
├── docs/                  # GitHub Pages用ファイル
│   ├── index.html
│   └── rss.xml
├── script/                # RSS生成スクリプト
│   └── export_rss.rb
├── .github/workflows/     # GitHub Actions
│   └── deploy.yml
├── .env                   # 環境変数ファイル
├── Gemfile                # Ruby依存関係
└── README.md
```

## アクセス方法

- **ポッドキャストページ**: https://ys7i.github.io/llm_podcast/
- **RSS フィード**: https://ys7i.github.io/llm_podcast/rss.xml

## 新しいエピソードの追加

1. 音声ファイルを`audio/`ディレクトリに追加
2. `script/export_rss.rb`にエピソード情報を追加
3. S3 に音声ファイルをアップロード
4. コミットしてプッシュ（自動デプロイ）

## 注意事項

- 音声ファイルは S3 に保存し、CloudFront 経由で配信されます
- GitHub Pages は静的ファイルのみ配信可能です
- 大きな音声ファイルは GitHub にコミットしないでください
- `.env`ファイルは Git にコミットしないでください（`.gitignore`に追加）
