require 'restclient/client'
require 'restclient/datatypes'
require 'restclient/error'
require 'restclient/util'
require 'restclient/protocol'
require 'restclient/object'

class Accessory < RestClient::Object
  attr_accessor :client

  def initialize(data = nil, client = nil, parse_object_id = nil)
    @client = client || RestClient.client
    @parse_object_id = parse_object_id
    super(RestClient::Protocol::CLASS_ACCESSORY, data, client)
  end

  # Loads all accessories
  def self.get(parse_object_id, parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, parse_object_id).get
  end

  def get
    @class_name == RestClient::Protocol::CLASS_ACCESSORY
    response = client.request(uri, :get, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def uri
    RestClient::Protocol.accessory_uri @parse_object_id
  end

  def save
    client.request uri, method, to_json, nil
  end

  def rest_api_hash
    self
  end

  def method
    @parse_object_id ? :put : :post
  end

end