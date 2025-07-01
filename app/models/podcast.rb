class Podcast < ApplicationRecord
  has_one_attached :cover_image, service: :cover_image
  has_one_attached :audio_file, service: :audio_file
  has_one_attached :transcript_file, service: :transcript

  before_validation :set_ep_count, on: :create

  private

  def set_ep_count
    return if ep_count.present?

    max_ep_count = Podcast.maximum(:ep_count) || 0
    self.ep_count = max_ep_count + 1
  end
end
