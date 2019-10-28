require 'multi_json'
require 'aws-sdk-route53'

module Itamae
  module Resource
    class Route53Record < File
      define_attribute :action, default: :create
      define_attribute :region, type: String, required: true
      define_attribute :profile, type: String, default: 'default'
      define_attribute :hosted_zone_id, type: String, required: true
      define_attribute :comment, type: String
      define_attribute :record_name, type: String, default_name: true
      define_attribute :type, type: String, required: true
      define_attribute :ttl, type: Integer, required: true
      define_attribute :value, type: [ String, Array ], required: true
      # define_attribute :set_identifier, type: String
      # define_attribute :weight, type: String
      # define_attribute :failover, type: String
      # define_attribute :health_check_id, type: String
      # define_attribute :traffic_policy_instance_id, type: String

      def pre_action
        attributes.record_name = attributes.record_name + '.' unless attributes.record_name[-1] == '.'
        credentials = Aws::SharedCredentials.new(profile_name: attributes.profile)
        @route53 = Aws::Route53::Client.new(region: attributes.region, credentials: credentials)

        @change_batch = define_change_batch
        resource_record_set = @change_batch[:changes][0][:resource_record_set]
        attributes.content = MultiJson.dump(resource_record_set, pretty: true)

        @resource_record_set = compare_record_values(fetch_record)

        case @current_action
        when :create
          attributes.exist = true
        when :upsert
          attributes.exist = true
        when :delete
          attributes.exist = false
        end

        send_tempfile
        compare_file if @current_action == :upsert
      end

      def set_current_attributes
        current.modified = false
      end

      def action_create
        return if current.exist
        @route53.change_resource_record_sets(
          change_batch: @change_batch,
          hosted_zone_id: attributes.hosted_zone_id
        )
      end

      def action_upsert
        @route53.change_resource_record_sets(
          change_batch: @change_batch,
          hosted_zone_id: attributes.hosted_zone_id
        )
      end

      def action_delete
        return unless current.exist
        @route53.change_resource_record_sets(
          change_batch: @change_batch,
          hosted_zone_id: attributes.hosted_zone_id
        )
      rescue Aws::Route53::Errors::InvalidChangeBatch => e
        Itamae.logger.warn e.inspect
      end

      private

      def define_change_batch
        if attributes.value.class == Array
          resource_records = attributes.value.map do |v|
            { value: v }
          end
        elsif attributes.value.class == String
          resource_records = Array.new(1, { value: attributes.value })
        end

        resource_record_set = {
          name: attributes.record_name,
          type: attributes.type,
          ttl: attributes.ttl,
          resource_records: resource_records
        }

        changes = {
          action: attributes.action.to_s.upcase,
          resource_record_set: resource_record_set
        }

        {
          changes: [ changes ],
          comment: attributes.comment
        }
      end

      def fetch_record
        resp = @route53.list_resource_record_sets(
          hosted_zone_id: attributes.hosted_zone_id,
          start_record_name: attributes.record_name,
          start_record_type: attributes.type,
          start_record_identifier: attributes.set_identifier,
          max_items: 1
        )

        resp.resource_record_sets[0]
      end

      def compare_record_values(resource_record_set)
        if attributes.record_name == resource_record_set.name && attributes.type == resource_record_set.type
          current.exist = true
          resource_record_set.to_h
        else
          current.exist = false
          {}
        end
      end

      def compare_to
        if current.exist
          f = Tempfile.open('itamae')
          f.write(MultiJson.dump(@resource_record_set, pretty: true))
          f.close
          f.path
        else
          '/dev/null'
        end
      end

      def show_content_diff
        if attributes.modified
          Itamae.logger.info 'Convert resource record set to JSON and display the difference.'
        end

        super
      end
    end
  end
end
