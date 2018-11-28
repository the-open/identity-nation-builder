require 'rails_helper'

describe IdentityNationBuilder do
  context '#push' do
    before(:each) do
      @sync_id = 1
      Member.all.destroy_all
      2.times { FactoryBot.create(:member) }
      FactoryBot.create(:member_without_email)
      @members = Member.all
    end
    context 'event rsvp' do
      context 'with valid parameters' do
        it 'yeilds members_with_emails' do
          external_system_params = JSON.generate({'sync_type' => 'rsvp', 'event_id' => 1})
          IdentityNationBuilder.push(@sync_id, @members, external_system_params) do |members_with_emails, campaign_name|
            expect(members_with_emails.count).to eq(3)
          end
        end
      end
    end
    context 'list tag' do
      context 'with valid parameters' do
        it 'yeilds members_with_emails' do
          external_system_params = JSON.generate({'sync_type' => 'tag', 'tag' => 'test_tag'})
          IdentityNationBuilder.push(@sync_id, @members, external_system_params) do |members_with_emails, campaign_name|
            expect(members_with_emails.count).to eq(3)
          end
        end
      end
    end
  end

  context '#push_in_batches' do
    before(:each) do
      @sync_id = 1
      Member.all.destroy_all
      2.times { FactoryBot.create(:member) }
      @members = Member.all
    end
    context 'event rsvp' do
      context 'with valid parameters' do
        it 'yeilds write_result_count' do
          external_system_params = JSON.generate({'sync_type' => 'rsvp', 'event_id' => 1})
          expect(IdentityNationBuilder::API).to receive(:rsvp).exactly(1).times.with(anything, anything, anything) { 2 }
          IdentityNationBuilder.push_in_batches(1, @members, external_system_params) do |batch_index, write_result_count|
            expect(write_result_count).to eq(2)
          end
        end
      end
    end
    context 'list tag' do
      context 'with valid parameters' do
        it 'yeilds write_result_count' do
          external_system_params = JSON.generate({'sync_type' => 'tag', 'tag' => 'test_tag'})
          expect(IdentityNationBuilder::API).to receive(:tag).exactly(1).times.with(anything, anything, anything) { 2 }
          IdentityNationBuilder.push_in_batches(1, @members, external_system_params) do |batch_index, write_result_count|
            expect(write_result_count).to eq(2)
          end
        end
      end
    end
  end
end
