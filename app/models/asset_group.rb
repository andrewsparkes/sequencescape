# Groups a set of {Asset assets} together
# Primarily used to group together assets as part of an {Order order}.
class AssetGroup < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::AssetGroup
  include SharedBehaviour::Named

  belongs_to :study
  belongs_to :user
  belongs_to :submission # Optional, present if created by a particular submission

  has_many :asset_group_assets
  has_many :assets, through: :asset_group_assets
  has_many :samples, through: :assets, source: :samples

  validates :name, presence: true, uniqueness: true
  validates :study, presence: true

  scope :for_search_query, ->(query) { where(['name LIKE ?', "%#{query}%"]) }

  def all_samples_have_accession_numbers?
    unaccessioned_samples.empty?
  end

  # The has many through only works if the asset_group_assets are stored in the database,
  # which won't be the case for new records. We depend on checking this on unsaved
  # asset groups during the submission process. Here we switch between to scopes.
  def unaccessioned_samples
    if new_record?
      Sample.contained_in(assets).without_accession
    else
      samples.without_accession
    end
  end

  def self.find_or_create_asset_group(new_assets_name, study)
    # Is new name set or create group
    asset_group = nil
    if new_assets_name.present?
      asset_group = AssetGroup.create_with(study: study).find_or_create_by(name: new_assets_name)
    end
    asset_group
  end

  def automatic_move?
    asset_types.one? && assets.first.automatic_move?
  end

  def asset_types
    assets.map(&:sti_type).uniq
  end

  def duplicate(project)
    # TODO: Implement me
  end

  def move(assets)
    # TODO: Implement me
  end
end
