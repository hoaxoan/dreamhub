# encoding: utf-8
require 'restclient/protocol'
require 'restclient/error'
require 'restclient/util'

require 'logger'

# This module contains all the code
module RestClient
  # The client that communicates with the RestClient server via REST
  class Client
    RETRIED_EXCEPTIONS = [
        'Faraday::Error::TimeoutError',
        'Faraday::Error::ParsingError',
        'Faraday::Error::ConnectionFailed',
        'RestClient::RestClientProtocolRetry'
    ]

    attr_accessor :host
    attr_accessor :path
    attr_accessor :user_id
    attr_accessor :session_token
    attr_accessor :session
    attr_accessor :max_retries
    attr_accessor :logger
    attr_accessor :quiet
    attr_accessor :timeout
    attr_accessor :interval
    attr_accessor :backoff_factor
    attr_accessor :retried_exceptions
    attr_reader :get_method_override

    def initialize(data = {}, &_blk)
      @host           = data[:host] || Protocol::HOST
      @path           = data[:path] || Protocol::PATH
      @user_id        = data[:user_id]
      @session_token  = data[:session_token]
      @max_retries    = data[:max_retries] || 3
      @logger         = data[:logger] || Logger
                                             .new(STDERR).tap { |l| l.level = Logger::INFO }
      @quiet          = data[:quiet] || false
      @timeout        = data[:timeout] || 30

      # Additional parameters for Faraday Request::Retry
      @interval       = data[:interval] || 0.5
      @backoff_factor = data[:backoff_factor] || 2

      @retried_exceptions = RETRIED_EXCEPTIONS
      @retried_exceptions += data[:retried_exceptions] if data[
          :retried_exceptions]

      @get_method_override = data[:get_method_override]

      options = { request: { timeout: @timeout, open_timeout: @timeout } }

      @session = Faraday.new(host, options) do |c|
        c.request :json

        c.use Faraday::GetMethodOverride if @get_method_override

        c.use Faraday::BetterRetry,
              max: @max_retries,
              logger: @logger,
              interval: @interval,
              backoff_factor: @backoff_factor,
              exceptions: @retried_exceptions
        c.use Faraday::ExtendedParseJson

        c.response :logger, @logger unless @quiet

        c.adapter Faraday.default_adapter

        yield(c) if block_given?
      end
    end

    # Perform an HTTP request for the given uri and method
    # with common basic response handling. Will raise a
    # RestClientProtocolError if the response has an error status code,
    # and will return the parsed JSON body on success, if there is one.
    def request(uri, method = :get, body = nil, query = nil, content_type = nil)
      headers = {}

      {
          'Content-Type'                  => content_type || 'application/json',
          'User-Agent'                    => "RestClient for Ruby, 1.0",
          Protocol::HEADER_USER_ID        => @user_id,
          Protocol::HEADER_SESSION_TOKEN  => @session_token
      }.each do |key, value|
        headers[key] = value if value
      end

      uri = ::File.join(path, uri)
      @session.send(method, uri, query || body || {}, headers).body

        # NOTE: Don't leak our internal libraries to our clients.
        # Extend this list of exceptions as needed.
    rescue Faraday::Error::ClientError => e
      raise RestClient::ConnectionError, e.message
    end

    def get(uri)
      request(uri)
    end

    def post(uri, body)
      request(uri, :post, body)
    end

    def put(uri, body)
      request(uri, :put, body)
    end

    def delete(uri)
      request(uri, :delete)
    end

    def object(class_name, data = nil)
      RestClient::Object.new(class_name, data, self)
    end

  end

  # Module methods
  # ------------------------------------------------------------
  class << self
    # A singleton client for use by methods in Object.
    # Always use RestClient.client to retrieve the client object.
    @client = nil

    # Factory to create instances of Client.
    # This should be preferred over RestClient.init which uses a singleton
    # client object for all API calls.
    def create(data = {}, &blk)
      defaults = {
          get_method_override: true
      }
      defaults.merge!(data)

      # use less permissive key if both are specified
      unless data[:user_id]
        defaults[:user_id] = ENV['USER_ID_KEY']
      end

      Client.new(defaults, &blk)
    end

    # DEPRECATED: Please use create instead.
    # Initialize the singleton instance of Client which is used
    # by all API methods. Parse.init must be called before saving
    # or retrieving any objects.
    def init(data = {}, &blk)
      warn '[DEPRECATION] `init` is deprecated.  Please use `create` instead.'
      @@client = create(data, &blk)
    end

    # Used mostly for testing. Lets you delete the api key global vars.
    def destroy
      @@client = nil
      self
    end

    def client
      raise RestClientError, 'API not initialized' unless @@client
      @@client
    end

    # Perform a simple retrieval of a simple object, or all objects of a
    # given class. If object_id is supplied, a single object will be
    # retrieved. If object_id is not supplied, then all objects of the
    # given class will be retrieved and returned in an Array.
    # Accepts an explicit client object to avoid using the legacy singleton.
    def get(class_name, object_id = nil, parse_client = nil)
      c = parse_client || client
      data = c.get(Protocol.class_uri(class_name, object_id))
      object = RestClient.parse_json(class_name, data)
      object = RestClient.copy_client(c, object)
      object
    rescue RestClientProtocolError => e
      if e.code == Protocol::ERROR_OBJECT_NOT_FOUND_FOR_GET
        e.message += ": #{class_name}:#{object_id}"
      end
      raise
    end
  end
end