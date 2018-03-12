
module Itamae
  module Resource
    class HttpRequest
      def pre_action
        attributes.content = fetch_content
        current.exist = run_specinfra(:check_file_is_file, attributes.path)
        attributes.exist = true

        send_tempfile
        compare_file
      end

      def show_differences
        current.mode    = current.mode.rjust(4, '0') if current.mode
        attributes.mode = attributes.mode.rjust(4, '0') if attributes.mode

        @current_attributes.each_pair do |key, current_value|
          value = @attributes[key]
          if current_value.nil? && value.nil?
            # ignore
          elsif current_value.nil? && !value.nil?
            Itamae.logger.color :green do
              Itamae.logger.info "#{resource_type}[#{resource_name}] #{key} will be '#{value}'"
            end
          elsif current_value == value || value.nil?
            Itamae.logger.debug "#{resource_type}[#{resource_name}] #{key} will not change (current value is '#{current_value}')"
          else
            Itamae.logger.color :green do
              Itamae.logger.info "#{resource_type}[#{resource_name}] #{key} will change from '#{current_value}' to '#{value}'"
            end
          end
        end

        show_content_diff
      end

      def fetch_content
        uri = URI.parse(attributes.url)
        response = nil
        redirects_followed = 0

        loop do
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == "https"

          case @current_action
          when :delete, :get, :options
            response = http.method(@current_action).call(uri.request_uri, attributes.headers)
          when :post, :put
            response = http.method(@current_action).call(uri.request_uri, attributes.message, attributes.headers)
          end

          if response.kind_of?(Net::HTTPRedirection)
            if redirects_followed < attributes.redirect_limit
              uri = URI.parse(response["location"])
              redirects_followed += 1
              ItamaeMitsurin.logger.debug "Following redirect #{redirects_followed}/#{attributes.redirect_limit}"
            else
              raise RedirectLimitExceeded
            end
          else
            break
          end
        end

        response.body
      end
    end
  end
end
