# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.0.2 API application for managing podcast content and articles, with text-to-speech conversion capabilities. The app converts text files to audio using Google Cloud Text-to-Speech API and manages podcast episodes with S3 storage for audio files, cover images, and transcripts.

## Architecture

### Models
- **Podcast**: Manages podcast episodes with ActiveStorage attachments for cover images, audio files, and transcripts stored in separate S3 buckets
- **Article**: Represents articles that can be converted to podcast content, with status tracking (`script_status` enum: waiting/done) and URL validation

### Controllers
- **API::V1::ArticlesController**: RESTful API for article management (no destroy action)
- Health check endpoint available at `/up`

### Core Services
- **TextToSpeechConverter** (`lib/text_to_speech_converter.rb`): Converts text files to MP3 using Google Cloud TTS with multi-speaker support
  - Supports conversation format with speaker prefixes (e.g., "A: Hello", "B: Hi")
  - Uses different voices for different speakers automatically
  - Configurable voice options and audio settings

### Storage Configuration
- Local disk storage for development/test
- S3 storage for production with separate buckets/prefixes:
  - Cover images: `photo/` prefix
  - Audio files: `audio/` prefix  
  - Transcripts: `transcript/` prefix
- Region: ap-northeast-3, Bucket: llm-podcast

## Development Commands

### Setup
```bash
bundle install
bin/rails db:setup
```

### Running the Application
```bash
bin/rails server
```

### Database Operations
```bash
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:reset
```

### Testing
```bash
bin/rails spec                    # Run all specs
bin/rails spec:models            # Run model specs only
bin/rails spec:controllers       # Run controller specs only
```

### Code Quality
```bash
bundle exec rubocop             # Run RuboCop linter (uses omakase style)
bundle exec brakeman           # Security analysis
```

### Text-to-Speech Conversion
```bash
ruby scripts/exec.rb           # Convert sample.txt to MP3
```

### RSS Feed Generation
```bash
ruby scripts/export_rss.rb     # Generate RSS feed and HTML for GitHub Pages
```

## Testing Framework

- Uses RSpec for testing
- FactoryBot for test data creation
- Factories available for Article and Podcast models
- Configuration in `.rspec` and `spec/rails_helper.rb`

## Key Dependencies

- Rails 8.0.2 with SQLite3 database
- AWS SDK for S3 integration
- Google Cloud Text-to-Speech (configured via service account key)
- RSpec, FactoryBot for testing
- Puma web server
- Solid Cache/Queue/Cable for Rails background processing

## Environment Configuration

The application expects these environment variables for RSS generation:
- `CLOUDFRONT_DOMAIN`: CloudFront distribution domain
- `S3_BUCKET_NAME`: S3 bucket name  
- `GITHUB_PAGES_URL`: GitHub Pages URL for the podcast

Google Cloud credentials should be configured via `service-account-key.json` or Rails credentials for S3 access.