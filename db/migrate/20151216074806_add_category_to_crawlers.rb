class AddCategoryToCrawlers < ActiveRecord::Migration
  def change
    add_column :crawlers, :category, :string
  end
end
