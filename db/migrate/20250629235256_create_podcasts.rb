class CreatePodcasts < ActiveRecord::Migration[8.0]
  def change
    create_table :podcasts do |t|
      t.integer :ep_count, null: false
      t.string :title, null: false
      t.string :description, null: false
      t.datetime :publish_date

      t.timestamps
    end
  end
end
