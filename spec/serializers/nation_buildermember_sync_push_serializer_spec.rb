describe IdentityNationBuilder::NationBuilderMemberSyncPushSerializer do
  context 'serialize' do
    before(:each) do
      Member.all.destroy_all
      @member = Member.create!(name: 'Freddy Kruger', email: 'nosleeptill@elmstreet.com')
      list = List.create(name: 'test list')
      ListMember.create(list: list, member: @member)
      Member.create!(name: 'Miles Davis', email: 'jazz@vibes.com')
      Member.create!(name: 'Yoko Ono')
      @batch_members = Member.all.with_email.in_batches.first
    end

    it 'returns valid object' do
      rows = ActiveModel::Serializer::CollectionSerializer.new(
        @batch_members,
        serializer: IdentityNationBuilder::NationBuilderMemberSyncPushSerializer
      ).as_json
      expect(rows.count).to eq(2)
      expect(rows[0][:email]).to eq(ListMember.first.member.email)
      expect(rows[0][:phone]).to eq(ListMember.first.member.landline)
      expect(rows[0][:mobile]).to eq(ListMember.first.member.mobile)
      expect(rows[0][:first_name]).to eq(ListMember.first.member.first_name)
      expect(rows[0][:last_name]).to eq(ListMember.first.member.last_name)
    end
  end
end
