require 'restclient/client'
require 'restclient/datatypes'
require 'restclient/error'
require 'restclient/util'
require 'restclient/protocol'
require 'restclient/object'

class Reservation < RestClient::Object
  attr_accessor :client

  def initialize(data = nil, client = nil, parse_object_id = nil)
    @client = client || RestClient.client
    @parse_object_id = parse_object_id
    super(RestClient::Protocol::CLASS_RESERVATION, data, client)
  end

  def self.get(parse_object_id, parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, parse_object_id).get
  end

  def self.reservation_approval(parse_object_id, parse_client = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, parse_object_id).reservation_approval
  end

  def self.reservationByReferNumber(referNumber = nil)
    parse_client ||= RestClient.client
    new(nil, parse_client, nil).reservationByReferNumber(referNumber)
  end

  def get
    @class_name == RestClient::Protocol::CLASS_RESERVATION
    response = client.request(uri, :get, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def reservation_approval
    @class_name == RestClient::Protocol::CLASS_RESERVATION
    response = client.request(reservation_approval_uri, :post, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def reservationByReferNumber(referNumber = nil)
    @class_name == RestClient::Protocol::CLASS_RESERVATION
    response = client.request(reservation_referNumber_uri(referNumber), :get, nil, nil)
    parse RestClient.parse_json(@class_name, response) if response
  end

  def uri
    RestClient::Protocol.reservation_uri @parse_object_id
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

  def reservation_approval_uri(reservation_id = nil)
    if reservation_id
      "/Reservations/#{reservation_id}/Approval"
    end
  end

  def reservation_referNumber_uri(referNumber = nil)
    if referNumber
      "/Reservations/#{referNumber}"
    end
  end

end