require 'restclient/client'
require 'restclient/datatypes'
require 'restclient/error'
require 'restclient/util'
require 'restclient/protocol'
require 'restclient/object'

class UserBook < RestClient::Object
  attr_accessor :client

  def initialize(data = nil, client = nil, parse_object_id = nil)
    @client = client || RestClient.client
    @parse_object_id = parse_object_id
    super(RestClient::Protocol::CLASS_USER, data, client)
  end

  def self.authenticate(username, password, client = nil)
    body = {
        'username' => username,
        'password' => password
    }

    client ||= RestClient.client
    response = client.request(
        RestClient::Protocol::USER_LOGIN_URI, :post, nil, body)
    client.session_token = response[RestClient::Protocol::KEY_USER_SESSION_TOKEN]
    client.user_id = response[RestClient::Protocol::KEY_USER_ID]

    new(response, client)
  end

  def self.get(parse_object_id, parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, parse_object_id).get
  end

  def get
    @class_name == RestClient::Protocol::CLASS_USER
    response = client.request(uri, :get, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def uri
    RestClient::Protocol.user_uri @parse_object_id
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