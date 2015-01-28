class RequestFactory
  def self.copy_request(request)
    ActiveRecord::Base.transaction do

      metadata_attributes = request.request_metadata.attributes
      metadata_attributes.delete_if {|key,value| ['created_at','updated_at','request_id','id'].include?(key) }

      request.class.create!(request.attributes) do |request_copy|
        request_copy.target_asset_id  = nil
        request_copy.state            = "pending"
        request_copy.request_metadata_attributes = metadata_attributes
        request_copy.created_at       = Time.now
      end
    end
  end

  def self.create_assets_requests(assets, study)
    # internal requests to link study -> request -> asset -> sample
    # TODO: do this as a submission
    request_type = RequestType.find_by_key('create_asset') or raise StandardError, "Cannot find create asset request type"
    assets.each { |asset| request_type.create!(:study => study, :asset => asset, :state => 'passed') }
  end
end
