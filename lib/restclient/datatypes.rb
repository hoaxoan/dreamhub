# encoding: utf-8
require 'time'
require 'date'
require 'base64'

module RestClient
  # A pointer to a Parse object
  # https://parse.com/docs/rest/guide/#objects-data-types
  class Pointer
    attr_accessor :parse_object_id
    attr_accessor :class_name
    alias id parse_object_id

    def self.make(class_name, object_id)
      Pointer.new(
          Protocol::KEY_CLASS_NAME => class_name,
          Protocol::KEY_OBJECT_ID => object_id
      )
    end

    def initialize(data)
      @class_name       = data[Protocol::KEY_CLASS_NAME]
      @parse_object_id  = data[Protocol::KEY_OBJECT_ID]
    end

    # make it easier to deal with the ambiguity of whether
    # you're passed a pointer or object
    def pointer
      self
    end

    def eql?(other)
      RestClient.object_pointer_equality?(self, other)
    end
    alias == eql?

    def hash
      RestClient.object_pointer_hash(self)
    end

    def new?
      false
    end

    def to_h(*_a)
      {
          Protocol::KEY_TYPE        => Protocol::TYPE_POINTER,
          Protocol::KEY_CLASS_NAME  => @class_name,
          Protocol::KEY_OBJECT_ID   => @parse_object_id
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end

    # Retrieve the RestClient object referenced by this pointer.
    def get(client = nil)
      RestClient.get(@class_name, @parse_object_id, client) if @parse_object_id
    end

    def to_s
      "#{@class_name}:#{@parse_object_id}"
    end
  end

  # A RestClient Date
  # https://parse.com/docs/rest/guide/#objects-data-types
  class Date
    attr_accessor :value

    def initialize(data)
      if data.respond_to?(:iso8601)
        @value = data
      elsif data.is_a? Hash
        @value = DateTime.parse data['iso']
      elsif data.is_a? String
        @value = DateTime.parse data
      else
        raise "data doesn't act like time #{data.inspect}"
      end
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          value == other.value
    end
    alias == eql?

    def hash
      value.hash
    end

    def <=>(other)
      value <=> other.value
    end

    def method_missing(method, *args, &block)
      if value.respond_to?(method)
        value.send(method, *args, &block)
      else
        super(method)
      end
    end

    def respond_to?(method, include_private = false)
      super || value.respond_to?(method, include_private)
    end

    def to_h(*_a)
      {
          Protocol::KEY_TYPE => Protocol::TYPE_DATE,
          'iso'              => value.to_time.utc.iso8601(3)
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end
  end

  # Bytes
  class Bytes
    attr_accessor :value

    def initialize(data)
      bytes = data['base64']
      @value = Base64.decode64(bytes)
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          value == other.value
    end
    alias == eql?

    def hash
      value.hash
    end

    def <=>(other)
      value <=> other.value
    end

    def method_missing(method, *args, &block)
      if value.respond_to?(method)
        value.send(method, *args, &block)
      else
        super(method)
      end
    end

    def respond_to?(method, include_private = false)
      super || value.respond_to?(method, include_private)
    end

    def to_h(*_a)
      {
          Protocol::KEY_TYPE => Protocol::TYPE_BYTES,
          'base64' => Base64.encode64(@value)
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end
  end

  # Increment (or decrement) counter
  # https://parse.com/docs/rest/guide/#objects-counters
  class Increment
    attr_accessor :amount

    def initialize(amount)
      @amount = amount
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          amount == other.amount
    end
    alias == eql?

    def hash
      amount.hash
    end

    def to_h(*_a)
      {
          Protocol::KEY_OP => Protocol::KEY_INCREMENT,
          Protocol::KEY_AMOUNT => @amount
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end
  end

  # Array operation
  # https://parse.com/docs/rest/guide/#objects-arrays
  class ArrayOp
    attr_accessor :operation
    attr_accessor :objects

    def initialize(operation, objects)
      @operation = operation
      @objects = objects
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          operation == other.operation &&
          objects == other.objects
    end
    alias == eql?

    def hash
      operation.hash ^ objects.hash
    end

    def to_h(*_a)
      {
          Protocol::KEY_OP => operation,
          Protocol::KEY_OBJECTS => @objects
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end
  end

  # GeoPoint
  # https://parse.com/docs/rest/guide/#geopoints
  class GeoPoint
    attr_accessor :longitude, :latitude

    def initialize(data)
      @longitude = data['longitude'] || data[:longitude]
      @latitude  = data['latitude'] || data[:latitude]
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          longitude == other.longitude &&
          latitude == other.latitude
    end
    alias == eql?

    def hash
      longitude.hash ^ latitude.hash
    end

    def to_h(*_a)
      {
          Protocol::KEY_TYPE => Protocol::TYPE_GEOPOINT,
          'latitude' => @latitude,
          'longitude' => @longitude
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end

    def to_s
      "(#{latitude}, #{longitude})"
    end
  end

  # File
  # https://parse.com/docs/rest/guide/#files
  class File
    attr_accessor :local_filename
    attr_accessor :parse_filename
    attr_accessor :content_type
    attr_accessor :body
    attr_accessor :url
    attr_accessor :client

    def initialize(data, client = nil)
      # convert hash keys to strings
      data = Hash[data.map { |k, v| [k.to_s, v] }]

      @local_filename = data['local_filename'] if data['local_filename']
      @parse_filename = data['name']           if data['name']
      @parse_filename = data['parse_filename'] if data['parse_filename']
      @content_type   = data['content_type']   if data['content_type']
      @url            = data['url']            if data['url']
      @body           = data['body']           if data['body']
      @client         = client || RestClient.client
    end

    def eql?(other)
      self.class.equal?(other.class) &&
          url == other.url
    end
    alias == eql?

    def hash
      url.hash
    end

    def save
      uri = RestClient::Protocol.file_uri(@local_filename)
      resp = @client.request(uri, :post, @body, nil, @content_type)
      @parse_filename = resp['name']
      @url = resp['url']
      resp
    end

    def to_h(*_a)
      {
          Protocol::KEY_TYPE => Protocol::TYPE_FILE,
          'name' => @parse_filename,
          'url' => @url
      }
    end
    alias as_json to_h

    def to_json(*a)
      to_h.to_json(*a)
    end
  end
end