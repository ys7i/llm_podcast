class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :url, null: false
      t.references :podcast, null: true, foreign_key: true

      t.timestamps
    end
  end
end
