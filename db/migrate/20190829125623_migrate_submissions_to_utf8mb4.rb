# frozen_string_literal: true

# Autogenerated migration to convert submissions to utf8mb4
class MigrateSubmissionsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('submissions', from: 'latin1', to: 'utf8mb4')
  end
end
