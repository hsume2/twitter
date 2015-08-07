require 'faraday'
require 'json'

module Twitter
  module REST
    module Response
      class ParseJson < Faraday::Response::Middleware
        WHITESPACE_REGEX = /\A^\s*$\z/

        def parse(body)
          case body
          when WHITESPACE_REGEX, nil
            nil
          else
            JSON.parse(body, :symbolize_names => true)
          end
        end

        def on_complete(response)
          original_response_body = response.body
          response.body = parse(response.body) if respond_to?(:parse) && !unparsable_status_codes.include?(response.status)
          if response.body.nil? || response.body.is_a?(Symbol)
            @logger ||= begin
              require 'logger'
              ::Logger.new(STDOUT)
            end
            @logger.info "[#{self.class.name}##{__method__}] #{original_response_body.inspect}, #{response.body.inspect}"
          end
        end

        def unparsable_status_codes
          [204, 301, 302, 304]
        end
      end
    end
  end
end

Faraday::Response.register_middleware :twitter_parse_json => Twitter::REST::Response::ParseJson
