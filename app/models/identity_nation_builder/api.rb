require 'nationbuilder'

module IdentityNationBuilder
  class API
    def self.rsvp(site_slug, members, event_id)
      member_ids = members.map do |member|
        rsvp_person(site_slug, event_id, find_or_create_person(member))
      end
      member_ids.length
    end

    def self.tag(site_slug, members, tag)
      list_id = find_or_create_list(tag)['id']
      member_ids = members.map do |member|
        find_or_create_person(member)['id']
      end
      add_people_list(list_id, member_ids)
      tag_list(list_id, tag)
      member_ids.length
    end

    def self.sites
      api(:sites, :index, { per_page: 100 })['results']
    end

    def self.sites_events
      site_slugs = sites.map { |site| site['slug'] }
      all_upcoming_events(site_slugs)
    end

    private

    def self.all_upcoming_events(site_slugs)
      $event_results = []
      site_slugs.each do |slug|
        $page = NationBuilder::Paginator.new(get_api_client, events(slug))
        page_results = $page.body['results'].map { |result| result['site_slug'] = slug; result }
        $event_results = $event_results + page_results
        loop do
          break unless $page.next?
          $page = $page.next
          page_results = $page.body['results'].map { |result| result['site_slug'] = slug; result }
          $event_results = $event_results + page_results
        end
      end
      $event_results
    end

    def self.events(slug)
      api(:events, :index, { site_slug: slug, starting: Time.now(), per_page: 100 })
    end

    def self.find_or_create_person(member)
      api(:people, :add, { person: member })['person']
    end

    def self.rsvp_person(site_slug, event_id, person)
      api(:events, :rsvp_create, { id: event_id, site_slug: site_slug, rsvp: { person_id: person['id'] } })
    end

    def self.find_or_create_list(tag)
      matched_lists = all_lists.select {|list| list["slug"] == tag }
      matched_lists.any? ? matched_lists.first : create_list(tag)
    end

    def self.all_lists
      $list_results = []
      $page = NationBuilder::Paginator.new(get_api_client, lists)
      page_results = $page.body['results']
      $list_results = $list_results + page_results
      loop do
        break unless $page.next?
        $page = $page.next
        page_results = $page.body['results']
        $list_results = $list_results + page_results
      end
      $list_results
    end

    def self.lists
      api(:lists, :index, { per_page: 100 })
    end

    def self.create_list(tag)
      api(:lists, :create, { list: { name: tag, slug: tag, author_id: Settings.nation_builder.author_id } })['list_resource']
    end

    def self.add_people_list(list_id, member_ids)
      api(:lists, :add_people, { list_id: list_id, people_ids: member_ids })
    end

    def self.tag_list(list_id, tag)
      api(:lists, :add_tag, { list_id: list_id, tag: tag })
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
        raise unless payload_has_a_no_match_code?(payload) || attempt_to_rsvp_person_twice(args[1], e.message)
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

    def self.attempt_to_rsvp_person_twice(api_call, error)
      api_call == :rsvp_create && error.include?("signup_id has already been taken")
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