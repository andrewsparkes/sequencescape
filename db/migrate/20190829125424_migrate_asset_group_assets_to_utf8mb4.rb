# frozen_string_literal: true

# Autogenerated migration to convert asset_group_assets to utf8mb4
class MigrateAssetGroupAssetsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('asset_group_assets', from: 'latin1', to: 'utf8mb4')
  end
end