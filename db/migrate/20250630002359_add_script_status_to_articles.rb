class AddScriptStatusToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :script_status, :integer
  end
end
