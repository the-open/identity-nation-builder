FactoryBot.define do
  factory :subscription do
    factory :calling_subscription do
      id { Subscription::CALLING_SUBSCRIPTION }
      name { 'Calling' }
    end
    factory :email_subscription do
      id { Subscription::EMAIL_SUBSCRIPTION }
      name { 'Email' }
    end
    factory :nation_builder_subscription do
      id { Settings.nation_builder.opt_out_subscription_id }
      name { 'NationBuilder Calling' }
    end
  end
end
