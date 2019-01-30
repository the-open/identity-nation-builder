require 'rails_helper'

describe IdentityNationBuilder do
  context 'fetching new events' do

    let!(:events_response){ JSON.parse(File.read("spec/fixtures/events_response.json")) }
    let!(:event_rsvp_response){ JSON.parse(File.read("spec/fixtures/event_rsvp_response.json")) }
    let!(:person_response){ JSON.parse(File.read("spec/fixtures/person_response.json")) }

    before(:all) do
      Sidekiq::Testing.inline!
    end

    before(:each) do
      clean_external_database

      IdentityNationBuilder::API.should_receive(:sites_events).and_return(events_response["results"])
      IdentityNationBuilder::API.should_receive(:all_event_rsvps).exactly(2).times.with(anything, anything).and_return(event_rsvp_response["results"])
      IdentityNationBuilder::API.should_receive(:person).exactly(6).times.with(anything).and_return(person_response["person"])
    end

    after(:all) do
      Sidekiq::Testing.fake!
    end

    it 'should fetch the new events and insert them' do
      IdentityNationBuilder.fetch_new_events
      expect(Event.count).to eq(2)
    end

    it 'should record all event details' do
      IdentityNationBuilder.fetch_new_events
      nb_event = events_response["results"][0]
      event_location = IdentityNationBuilder.event_address_full(nb_event)
      expect(Event.first).to have_attributes(
        name: nb_event['name'],
        start_time: DateTime.parse(nb_event['start_time']),
        end_time: DateTime.parse(nb_event['end_time']),
        description: nb_event['intro'],
        location: event_location,
        latitude: Float(nb_event['venue']['address']['lat']),
        longitude: Float(nb_event['venue']['address']['lng']),
        max_attendees: Integer(nb_event['capacity']),
        approved: nb_event['status'] == 'published',
        invite_only: !nb_event['rsvp_form']['allow_guests']
      )
    end

    it 'should fetch people and upsert members' do
      IdentityNationBuilder.fetch_new_events
      expect(Member.count).to eq(1)
    end

    it 'should record member details' do
      IdentityNationBuilder.fetch_new_events
      expect(Member.last).to have_attributes(
        first_name: person_response['person']['first_name'],
        last_name: person_response['person']['last_name'],
        email: person_response['person']['email']
      )
    end

    it 'should fetch the new event rsvps and insert them' do
      IdentityNationBuilder.fetch_new_events
      expect(EventRsvp.count).to eq(2)
    end

    context 'with an event without an address' do
      it 'should use the event name as the location' do
        events_without_venue_address = events_response['results']
        events_without_venue_address.first['venue'].delete('address')
        IdentityNationBuilder::API.stub(:sites_events).and_return(events_without_venue_address)
        IdentityNationBuilder.fetch_new_events
        event = Event.first
        expect(event.location).to include(events_without_venue_address.first['venue']['name'])
        expect(event.latitude).to be_nil
        expect(event.longitude).to be_nil
      end
    end
  end
end
