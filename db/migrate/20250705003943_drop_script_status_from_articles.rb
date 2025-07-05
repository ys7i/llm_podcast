class DropScriptStatusFromArticles < ActiveRecord::Migration[8.0]
  def change
    remove_column :articles, :script_status, :integer
  end
end
