# encoding: utf-8
module RestClient
  # A meta object to find objects by object id
  class Model < RestClient::Object
    def initialize(data = nil, parse_client = nil)
      super(self.class.to_s, data, parse_client || Parse.client)
    end

    def self.find(object_id, client = nil)
      data = RestClient::Query.new(to_s, client).eq('objectId', object_id).first
      new(data, client)
    end

  end
end
