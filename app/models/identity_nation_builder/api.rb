require 'nationbuilder'

module IdentityNationBuilder
  class API
    def self.rsvp(member, event_id)
      rsvp_person(event_id, find_or_create_person(member))
    end

    private

    def self.find_or_create_person(member)
      api(:people, :add, { person: member })['person']
    end

    def self.rsvp_person(event_id, person)
      api(:events, :rsvp_create, { id: event_id, site_slug: site_slug, rsvp: { person_id: person['id'] } })
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

    def self.site_slug
      ENV['NATIONBUILDER_SITE_SLUG']
    end

    def self.get_api_client
      NationBuilder::Client.new ENV['NATIONBUILDER_SITE'], ENV['NATIONBUILDER_TOKEN'], retries: 0
    end

    def self.payload_has_a_no_match_code?(payload)
      payload && payload['code'] == 'no_matches'
    end

    def self.raise_if_empty_payload(payload)
      raise RuntimeError, 'Empty payload returned from NB API - likely due to Rate Limiting' if payload.nil?
    end

    def self.log_api_call(started_at, payload, *call_args)
      return unless ENV['NATIONBUILDER_DEBUG']
      data = {
        started_at: started_at, payload: payload, completed_at: DateTime.now,
        endpoint: call_args[0..1].join('/'), data: call_args.third,
      }
      puts "NationBuilder API: #{data.inspect}"
    end
  end
end
