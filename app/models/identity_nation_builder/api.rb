require 'nationbuilder'

module IdentityNationBuilder
  class API
    def self.rsvp(members, event_id, tag)
      member_ids = members.map do |member|
        rsvp_person(event_id, find_or_create_person(member))
      end
      member_ids.length
    end

    def self.tag(members, event_id, tag)
      list_id = create_list(tag)['id']
      member_ids = members.map do |member|
        find_or_create_person(member)['id']
      end
      add_people_list(list_id, member_ids)
      tag_list(list_id, tag)
      member_ids.length
    end

    def self.events
      get_upcoming_events
    end

    private

    def self.get_upcoming_events
      api(:events, :index, { site_slug: Settings.nation_builder.site_slug, starting: Time.now() })['results']
    end

    def self.find_or_create_person(member)
      api(:people, :add, { person: member })['person']
    end

    def self.rsvp_person(event_id, person)
      api(:events, :rsvp_create, { id: event_id, site_slug: Settings.nation_builder.site_slug, rsvp: { person_id: person['id'] } })
    end

    def self.create_list(tag)
      api(:lists, :create, { site_slug: Settings.nation_builder.site_slug, list: { name: tag, slug: tag, author_id: Settings.nation_builder.author_id } })['list_resource']
    end

    def self.add_people_list(list_id, member_ids)
      api(:lists, :add_people, { site_slug: Settings.nation_builder.site_slug, list_id: list_id, people_ids: member_ids })['list_resource']
    end

    def self.tag_list(list_id, tag)
      api(:lists, :tag, { site_slug: Settings.nation_builder.site_slug, list_id: list_id, tag_name: tag })
    end

    def self.api(*args)
      args[2] = {} unless args.third
      args.third[:fire_webhooks] = false
      started_at = DateTime.now
      begin
        payload = get_api_client.call(*args)
        raise_if_empty_payload payload
      rescue NationBuilder::RateLimitedError
        raise
      rescue NationBuilder::ClientError => e
        payload = JSON.parse(e.message)
        raise unless payload_has_a_no_match_code?(payload)
      end
      log_api_call(started_at, payload, *args)
      payload
    end

    def self.get_api_client
      NationBuilder::Client.new Settings.nation_builder.site, Settings.nation_builder.token, retries: 0
    end

    def self.payload_has_a_no_match_code?(payload)
      payload && payload['code'] == 'no_matches'
    end

    def self.raise_if_empty_payload(payload)
      raise RuntimeError, 'Empty payload returned from NB API - likely due to Rate Limiting' if payload.nil?
    end

    def self.log_api_call(started_at, payload, *call_args)
      return unless Settings.nation_builder.debug
      data = {
        started_at: started_at, payload: payload, completed_at: DateTime.now,
        endpoint: call_args[0..1].join('/'), data: call_args.third,
      }
      puts "NationBuilder API: #{data.inspect}"
    end
  end
end
