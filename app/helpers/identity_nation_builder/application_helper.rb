module IdentityNationBuilder
  module ApplicationHelper
    def self.push_types_for_select
      [["Event RSVP", :rsvp], ["Tag", :tag]]
    end
    def self.events_for_select
      IdentityNationBuilder::API.events.map { |x| ["##{x['id']}: #{x['title']}", x['id']] }
    end
  end
end