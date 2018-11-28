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
        sync_type = JSON.parse(external_system_params)['sync_type']
        rows = ActiveModel::Serializer::CollectionSerializer.new(
          batch_members,
          serializer: NationBuilderMemberSyncPushSerializer
        ).as_json
        write_result_count = IdentityNationBuilder::API.send(sync_type, rows, sync_type_item(external_system_params))

        yield batch_index, write_result_count
      end
    rescue => e
      raise e
    end
  end

  def self.sync_type_item(external_system_params)
    case JSON.parse(external_system_params)['sync_type']
    when 'rsvp'
      JSON.parse(external_system_params)['event_id']
    when 'tag'
      JSON.parse(external_system_params)['tag']
    end
  end

  def self.description(external_system_params, contact_campaign_name)
    "#{SYSTEM_NAME.titleize} - #{JSON.parse(external_system_params)['sync_type'].titleize}: ##{sync_type_item(external_system_params)} (#{CONTACT_TYPE[JSON.parse(external_system_params)['sync_type']]})"
  end
end
