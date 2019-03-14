require 'rails_helper'

describe IdentityNationBuilder do
  context 'fetching new events' do
    let!(:events_response){ JSON.parse(File.read("spec/fixtures/events_response.json")) }
    let!(:event_rsvp_response){ JSON.parse(File.read("spec/fixtures/event_rsvp_response.json")) }
    let!(:person_response){ JSON.parse(File.read("spec/fixtures/person_response.json")) }
    let!(:person_mobileonly_response){ JSON.parse(File.read("spec/fixtures/person_mobileonly_response.json")) }

    before(:each) do
      clean_external_database

      Settings.stub_chain(:options, :default_phone_country_code) { '61' }
      Settings.stub_chain(:options, :default_mobile_phone_national_destination_code) { 4 }

      IdentityNationBuilder::API.stub_chain(:sites_events) { events_response["results"] }
    end

    context 'with SideKiq inline' do
      before(:each) do
        IdentityNationBuilder::API.stub_chain(:all_event_rsvps) { event_rsvp_response["results"] }
        IdentityNationBuilder::API.stub_chain(:person) { person_response["person"] }

        IdentityNationBuilder::API.should_receive(:all_event_rsvps).exactly(2).times.with(anything, anything)
        IdentityNationBuilder::API.should_receive(:person).exactly(6).times.with(anything)
      end

      before(:all) do
        Sidekiq::Testing.inline!
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
          start_time: nb_event['start_time'] && DateTime.parse(nb_event['start_time']),
          end_time: nb_event['end_date'] && DateTime.parse(nb_event['end_date']),
          description: nb_event['intro'],
          location: event_location,
          latitude: Float(nb_event['venue']['address']['lat']),
          longitude: Float(nb_event['venue']['address']['lng']),
          max_attendees: Integer(nb_event['capacity']),
          approved: nb_event['status'] == 'published',
          invite_only: !nb_event['rsvp_form']['allow_guests'],
          data: nb_event
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
          email: person_response['person']['email'],
          phone: person_response['person']['phone'] || person_response['person']['mobile']
        )
      end

      it 'should fetch the new event rsvps and insert them' do
        IdentityNationBuilder.fetch_new_events
        expect(EventRsvp.count).to eq(2)
        event = Event.where(external_id: 1).first
        event_rsvp = EventRsvp.where(event_id: event.id).first
        json_from_nb = event_rsvp_response["results"][2]
        expect(event_rsvp.data).to eq(json_from_nb)
      end
    end

    context 'with an event without an address' do
      it 'should use the event name as the location' do
        allow(IdentityNationBuilder).to receive(:fetch_new_event_rsvps).and_return(event_rsvp_response)
        Sidekiq::Testing.fake!
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

    context '#get_pull_batch_amount' do
      context 'with no settings parameters set' do
        it 'should return default class constant' do
          expect(IdentityNationBuilder.get_pull_batch_amount).to eq(100)
        end
      end
      context 'with settings parameters set' do
        before(:each) do
          Settings.stub_chain(:nation_builder, :pull_batch_amount) { 10 }
        end
        it 'should return set variable' do
          expect(IdentityNationBuilder.get_pull_batch_amount).to eq(10)
        end
      end
    end

    context 'person with mobile only' do
      before(:all) do
        Sidekiq::Testing.inline!
      end

      before(:each) do
        clean_external_database

        IdentityNationBuilder::API.stub_chain(:all_event_rsvps) { event_rsvp_response["results"] }
        IdentityNationBuilder::API.stub_chain(:person) { person_mobileonly_response["person"] }

        IdentityNationBuilder::API.should_receive(:all_event_rsvps).exactly(2).times.with(anything, anything)
        IdentityNationBuilder::API.should_receive(:person).exactly(6).times.with(anything)
      end

      it 'should record details of member who only has a mobile number' do
        mobile_last_three_digits = person_mobileonly_response['person']['mobile'].from(-3)
        IdentityNationBuilder.fetch_new_events
        expect(Member.last).to have_attributes(
          first_name: person_mobileonly_response['person']['first_name'],
          last_name: person_mobileonly_response['person']['last_name'],
          email: person_mobileonly_response['person']['email'],
        )
        expect(Member.last.phone).to include(mobile_last_three_digits)
      end
    end
  end
end
