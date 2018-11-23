module IdentityNationBuilder
  class NationBuilderMemberSyncPushSerializer < ActiveModel::Serializer
    attributes :email, :phone, :mobile, :first_name, :last_name

    def phone
      @object.landline
    end

    def mobile
      @object.mobile
    end
  end
end
