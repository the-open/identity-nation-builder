require "identity_nation_builder/engine"

module IdentityNationBuilder
  SYSTEM_NAME='nation_builder'
  BATCH_AMOUNT=10
  CONTACT_TYPE={'rsvp' => 'event', 'tag' => 'list'}

  def self.push(sync_id, members, external_system_params)
    begin
      yield members, nil
    rescue => e
      raise e
    end
  end

  def self.push_in_batches(sync_id, members, external_system_params)
    begin
      members.in_batches(of: BATCH_AMOUNT).each_with_index do |batch_members, batch_index|
        external_system_params_hash = JSON.parse(external_system_params)
        sync_type = external_system_params_hash['sync_type']
        site_slug = external_system_params_hash['site_slug']
        rows = ActiveModel::Serializer::CollectionSerializer.new(
          batch_members,
          serializer: NationBuilderMemberSyncPushSerializer
        ).as_json
        write_result_count = IdentityNationBuilder::API.send(sync_type, site_slug, rows, sync_type_item(external_system_params_hash))

        yield batch_index, write_result_count
      end
    rescue => e
      raise e
    end
  end

  def self.sync_type_item(external_system_params_hash)
    case external_system_params_hash['sync_type']
    when 'rsvp'
      external_system_params_hash['event_id']
    when 'tag'
      external_system_params_hash['tag']
    end
  end

  def self.description(external_system_params, contact_campaign_name)
    external_system_params_hash = JSON.parse(external_system_params)
    "#{SYSTEM_NAME.titleize} - #{external_system_params_hash['sync_type'].titleize}: ##{sync_type_item(external_system_params_hash)} (#{CONTACT_TYPE[external_system_params_hash['sync_type']]})"
  end
end
