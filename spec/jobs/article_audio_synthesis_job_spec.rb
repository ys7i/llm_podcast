require 'rails_helper'

RSpec.describe ArticleAudioSynthesisJob, type: :job do
  let(:article) { create(:article) }
  let(:podcast) { create(:podcast) }
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

      it 'does not process the article' do
        expect(Rails.logger).not_to receive(:info)
          .with("Starting audio synthesis for article #{article.id}")

        described_class.perform_now(article.id)
      end
    end

    context 'when article has a podcast_id' do
      before do
        article.update!(podcast: podcast)
        # Mock transcript file attachment
        allow(podcast).to receive(:transcript_file).and_return(double(attached?: true, download: "A: Hello\nB: World"))
      end

      it 'synthesizes audio for the article' do
        expect(mock_converter).to receive(:convert_file).with(anything)

        described_class.perform_now(article.id)
      end

      it 'marks the article as script done' do
        described_class.perform_now(article.id)

        article.reload
        expect(article.script_completed?).to be true
      end
    end

    context 'when article has a podcast but no transcript file' do
      before do
        article.update!(podcast: podcast)
        allow(podcast).to receive(:transcript_file).and_return(double(attached?: false))
      end

      it 'does not synthesize audio' do
        expect(mock_converter).not_to receive(:convert_file)

        described_class.perform_now(article.id)
      end
    end
  end
end
