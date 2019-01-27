require 'spec_helper'

describe IdentityNationBuilder::API do
  before do
    allow(Settings).to receive_message_chain(:nation_builder, :site).and_return('test')
    allow(Settings).to receive_message_chain(:nation_builder, :token).and_return('test')
    allow(Settings).to receive_message_chain(:nation_builder, :debug).and_return(false)
  end

  describe '.sites_events' do
    let!(:sites_request) {
      stub_request(:get, %r{sites})
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { results: [ { "id": 1, "slug": "test" } ] }.to_json
        )
    }
    let!(:events_request) {
      stub_request(:get, %r{events})
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { results: [ { "id": 2, "name": "test event", "site_slug": "test" } ] }.to_json
        )
    }

    describe '.cached_sites' do
      it "should return a list of cached sites from NationBuilder" do
        IdentityNationBuilder::API.sites_events
        expect(IdentityNationBuilder::API.cached_sites.length).to eq(1)
        expect(IdentityNationBuilder::API.cached_sites.first['slug']).to eq('test')
      end
    end

    describe '.cached_sites_events' do
      it "should return a list of cached sites from NationBuilder" do
        IdentityNationBuilder::API.sites_events
        expect(IdentityNationBuilder::API.cached_sites_events.length).to eq(1)
        expect(IdentityNationBuilder::API.cached_sites_events.first['name']).to eq('test event')
      end
    end
  end
end
