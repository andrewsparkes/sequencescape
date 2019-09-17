# frozen_string_literal: true

# Autogenerated migration to convert users to utf8mb4
class MigrateUsersToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('users', from: 'latin1', to: 'utf8mb4')
  end
end
