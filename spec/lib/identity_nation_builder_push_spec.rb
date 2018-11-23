require 'rails_helper'

describe IdentityNationBuilder do
  context '#push' do
    before(:each) do
      @sync_id = 1
      @external_system_params = JSON.generate({'event_id' => 1})
      Member.all.destroy_all
      2.times { FactoryBot.create(:member) }
      FactoryBot.create(:member_without_email)
      @members = Member.all
    end

    context 'with valid parameters' do
      it 'yeilds members_with_emails' do
        IdentityNationBuilder.push(@sync_id, @members, @external_system_params) do |members_with_emails, campaign_name|
          expect(members_with_emails.count).to eq(2)
        end
      end
    end
  end

  context '#push_in_batches' do
    before(:each) do
      expect(IdentityNationBuilder::API).to receive(:rsvp).exactly(2).times.with(anything, anything) {{ }}

      @sync_id = 1
      @external_system_params = JSON.generate({'event_id' => 1})
      Member.all.destroy_all
      2.times { FactoryBot.create(:member) }
      FactoryBot.create(:member_without_email)
      @members = Member.all.with_email
    end

    context 'with valid parameters' do
      #TODO update with write results
      it 'yeilds write_result_count' do
        IdentityNationBuilder.push_in_batches(1, @members, @external_system_params) do |batch_index, write_result_count|
          expect(write_result_count).to eq(0)
        end
      end
    end
  end
end
