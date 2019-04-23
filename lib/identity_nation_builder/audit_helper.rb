module IdentityNationBuilder
  module AuditHelper
    module ClassMethods
      def audit_method(object_string)
        external_count, local_count = eval('audit_'+object_string.underscore)
        return {
          external: external_count,
          local: local_count,
          diff: local_count - external_count
        }
      end

      def audit_event
        external_count = IdentityNationBuilder::API.sites_events().size
        local_count = Event.where(system: IdentityNationBuilder::SYSTEM_NAME).count
        return external_count, local_count
      end

      def audit_event_rsvp
        external_count = 0
        events = IdentityNationBuilder::API.sites_events()
        events.each do |nb_event|
          event_rsvps = IdentityNationBuilder::API.all_event_rsvps(nb_event['site_slug'], nb_event.external_id)
          external_count += event_rsvps.count
        end
        local_count = Event.joins(:event_rsvps).where(system: 'nation_builder').count
        return external_count, local_count
      end
    end
  end
end

