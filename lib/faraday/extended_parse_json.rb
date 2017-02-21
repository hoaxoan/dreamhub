# encoding: utf-8
module Faraday
  # A middleware to display error messages in the JSON response
  class ExtendedParseJson < FaradayMiddleware::ParseJson
    def process_response(env)
      env[:raw_body] = env[:body] if preserve_raw?(env)

      if env[:status] >= 400
        begin
          data = parse(env[:body]) || {}
        rescue StandardError
          data = {}
        end

        array_codes = [
          RestClient::Protocol::ERROR_INTERNAL,
          RestClient::Protocol::ERROR_TIMEOUT,
          RestClient::Protocol::ERROR_EXCEEDED_BURST_LIMIT
        ]
        error_hash = {
          'error' => "HTTP Status #{env[:status]} Body #{env[:body]}",
          'http_status_code' => env[:status]
        }.merge(data)
        if data['code'] && array_codes.include?(data['code'])
          sleep 60 if data['code'] == RestClient::Protocol::ERROR_EXCEEDED_BURST_LIMIT
          raise exception(env), error_hash.merge(data)
        elsif env[:status] >= 500
          raise exception(env), error_hash.merge(data)
        end
        raise RestClient::RestClientProtocolError, error_hash
      else
        data = parse(env[:body]) || {}
        env[:body] = data
      end
    end

    def exception(env)
      # NOTE: decide to retry or not, the header is deleted
      #  so it won't be sent to the server
      retries = env.request_headers.delete('X-ParseRubyClient-Retries')
      (retries.to_i.zero? ? RestClient::RestClientProtocolError : RestClient::RestClientProtocolRetry)
    end
  end
end
