require 'rails_helper'

RSpec.describe ArticleTranscriptGenerationJob, type: :job do
  let(:article) { create(:article) }

  describe '#perform' do
    context 'when article has no podcast_id' do
      before do
        article.update!(podcast_id: nil)
      end

      it 'creates a podcast for the article' do
        expect { described_class.perform_now(article.id) }
          .to change(Podcast, :count).by(1)

        article.reload
        expect(article.podcast).to be_present
        expect(article.podcast.title).to eq("Podcast from #{article.domain}")
      end

      it 'creates transcript file' do
        described_class.perform_now(article.id)

        article.reload
        podcast = article.podcast

        expect(podcast.transcript_file).to be_attached
      end

      it 'enqueues audio synthesis job' do
        expect(ArticleAudioSynthesisJob).to receive(:perform_later).with(article.id)

        described_class.perform_now(article.id)
      end
    end

    context 'when article already has a podcast_id' do
      let(:existing_podcast) { create(:podcast) }

      before do
        article.update!(podcast: existing_podcast)
      end

      it 'does not create a new podcast' do
        expect { described_class.perform_now(article.id) }
          .not_to change(Podcast, :count)
      end

      it 'does not process the article' do
        expect(Rails.logger).not_to receive(:info)
          .with("Starting transcript generation for article #{article.id}")

        described_class.perform_now(article.id)
      end
    end
  end
end
