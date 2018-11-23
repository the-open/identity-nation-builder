require "identity_nation_builder/engine"
require 'nationbuilder'

module IdentityNationBuilder
  SYSTEM_NAME='nation_builder'
  BATCH_AMOUNT=1
  SYNCING='rsvp'
  CONTACT_TYPE='event'

  def self.push(sync_id, members, external_system_params)
    begin
      yield members.with_email, nil
    rescue => e
      raise e
    end
  end

  def self.push_in_batches(sync_id, members, external_system_params)
    begin
      members.in_batches(of: BATCH_AMOUNT).each_with_index do |batch_members, batch_index|
        event_id = JSON.parse(external_system_params)['event_id']
        rows = ActiveModel::Serializer::CollectionSerializer.new(
          batch_members,
          serializer: NationBuilderMemberSyncPushSerializer
        )
        rows.each do |row|
          IdentityNationBuilder::API.rsvp(row, event_id)
        end

        #TODO return write results here
        yield batch_index, 0
      end
    rescue => e
      raise e
    end
  end

  def self.description(external_system_params, contact_campaign_name)
    "#{SYSTEM_NAME.titleize} - #{SYNCING.titleize}: ##{JSON.parse(external_system_params)['tag']} (#{CONTACT_TYPE})"
  end
end
