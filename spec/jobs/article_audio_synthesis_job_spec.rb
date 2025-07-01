require 'rails_helper'

RSpec.describe ArticleAudioSynthesisJob, type: :job do
  let(:article) { create(:article) }
  let(:mock_converter) { instance_double(TextToSpeechConverter) }
  let(:mock_audio_data) { "fake_audio_data" }

  before do
    allow(TextToSpeechConverter).to receive(:new).and_return(mock_converter)
    allow(mock_converter).to receive(:convert_file).and_return(mock_audio_data)
  end

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

      it 'creates transcript and audio files' do
        described_class.perform_now(article.id)

        article.reload
        podcast = article.podcast

        expect(podcast.transcript_file).to be_attached
        expect(podcast.audio_file).to be_attached
      end

      it 'marks the article as script done' do
        described_class.perform_now(article.id)

        article.reload
        expect(article.script_completed?).to be true
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
          .with("Starting audio synthesis for article #{article.id}")

        described_class.perform_now(article.id)
      end
    end
  end
end