module IdentityNationBuilder
  class NationBuilderMemberSyncPushSerializer < ActiveModel::Serializer
    attributes :email, :phone, :mobile, :first_name, :last_name

    def phone
      strip_country_code(@object.landline)
    end

    def mobile
      strip_country_code(@object.mobile)
    end

    private

    def strip_country_code(phone)
      code = Settings.options.try(:default_phone_country_code)
      code ? phone.try(:gsub, /^#{code}/, '0') : phone
    end
  end
end
