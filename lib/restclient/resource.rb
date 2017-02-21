require 'restclient/client'
require 'restclient/datatypes'
require 'restclient/error'
require 'restclient/util'
require 'restclient/protocol'
require 'restclient/object'

class Resource < RestClient::Object
  attr_accessor :client

  def initialize(data = nil, client = nil, parse_object_id = nil)
    @client = client || RestClient.client
    @parse_object_id = parse_object_id
    super(RestClient::Protocol::CLASS_RESOURCE, data, client)
  end

  # Loads all resources
  def self.get(parse_object_id, parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, parse_object_id).get
  end

  # Returns all available resource statuses
  def self.get_statuses(parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).get_statuses
  end

  # Returns all available resource status reasons
  def self.get_status_reasons(parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).get_status_reasons
  end

  # Returns all available resource types
  def self.get_resource_types(parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).get_resource_types
  end

  # Returns resource availability for the requested time. "availableAt" and "availableUntil" will
  # include availability through the next 7 days
  #Optional query string parameter: dateTime.
  # If no dateTime is requested the current datetime will be used.
  def self.get_resource_available(parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).get_resource_available
  end

  # Returns the full resource group tree
  def self.get_resource_groups(parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).get_resource_groups
  end

  def get
    @class_name == RestClient::Protocol::CLASS_RESOURCE
    response = client.request(uri, :get, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def get_statuses
    response = client.request(Resource.resource_statuses_uri, :get, nil, nil)
    parse RestClient.parse_json(nil, response) if response
  end

  def get_resource_types
    response = client.request(Resource.get_resource_types, :get, nil, nil)
    parse RestClient.parse_json(nil, response) if response
  end

  def get_resource_available
    response = client.request(Resource.resource_available_uri, :get, nil, nil)
    parse RestClient.parse_json(nil, response) if response
  end

  def get_resource_groups
    response = client.request(Resource.resource_groups_uri, :get, nil, nil)
    parse RestClient.parse_json(nil, response) if response
  end

  def get_status_reasons
    response = client.request(Resource.resource_status_reasons_uri, :get, nil, nil)
    parse RestClient.parse_json(nil, response) if response
  end

  def uri
    RestClient::Protocol.resource_uri @parse_object_id
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



  ## uri
  # Resource statuses
  def self.resource_statuses_uri
    'Resources/Status'
  end

  # Resource status reasons
  def self.resource_status_reasons_uri
    'Resources/Status/Reasons'
  end

  # Resource types
  def self.resource_types_uri
    'Resources/Types'
  end

  # Resource available
  def self.resource_available_uri
    'Resources/Availability'
  end

  # Resource group tree
  def self.resource_groups_uri
    'Resources/Groups'
  end


end