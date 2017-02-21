# encoding: utf-8
require 'restclient/protocol'
require 'restclient/client'
require 'restclient/error'

module RestClient
  # A Parse object
  # https://parse.com/docs/rest/guide/#objects
  class Object < Hash
    attr_reader :parse_object_id
    attr_reader :class_name
    attr_reader :created_at
    attr_reader :updated_at
    attr_accessor :client
    alias id parse_object_id

    def initialize(class_name, data = nil, client = nil)
      @class_name = class_name
      @op_fields = {}
      parse data if data
      @client = client || RestClient.client
    end

    def eql?(other)
      RestClient.object_pointer_equality?(self, other)
    end

    alias == eql?

    def hash
      RestClient.object_pointer_hash(self)
    end

    def uri
      Protocol.class_uri @class_name, @parse_object_id
    end

    def pointer
      RestClient::Pointer.new(rest_api_hash) unless new?
    end

    # make it easier to deal with the ambiguity of whether
    # you're passed a pointer or object
    def get
      self
    end

    def new?
      self['objectId'].nil?
    end

    def update_attributes(data = {})
      data.each_pair { |k, v| self[k] = v }
      save
    end

    # Write the current state of the local object to the API.
    # If the object has never been saved before, this will create
    # a new object, otherwise it will update the existing stored object.
    def save
      if @parse_object_id
        method = :put
        merge!(@op_fields) # use ops instead of our own view of the columns
      else
        method = :post
      end

      body = safe_hash.to_json
      data = @client.request(uri, method, body)

      if data
        # array ops can return mutated view of array which needs to be parsed
        object = RestClient.parse_json(class_name, data)
        object = RestClient.copy_client(@client, object)
        parse object
      end

      if @class_name == RestClient::Protocol::CLASS_USER
        delete('password')
        delete(:username)
        delete(:password)
      end

      self
    end

    # representation of object to send on saves
    def safe_hash
      Hash[map do |key, value|
             if Protocol::RESERVED_KEYS.include?(key)
               nil
             elsif value.is_a?(Hash) &&
                 value[Protocol::KEY_TYPE] == Protocol::TYPE_RELATION
               nil
             elsif value.nil?
               [key, Protocol::DELETE_OP]
             else
               [key, RestClient.pointerize_value(value)]
             end
           end.compact]
    end

    # full REST api representation of object
    def rest_api_hash
      merge(RestClient::Protocol::KEY_CLASS_NAME => class_name)
    end

    # Handle the addition of Array#to_h in Ruby 2.1
    def should_call_to_h?(value)
      value.respond_to?(:to_h) && !value.is_a?(Array)
    end

    def to_h(*_a)
      Hash[rest_api_hash.map do |key, value|
             [key, should_call_to_h?(value) ? value.to_h : value]
           end]
    end

    alias as_json to_h
    alias to_hash to_h

    def to_json(*a)
      to_h.to_json(*a)
    end

    def to_s
      "#{@class_name}:#{@parse_object_id} #{super}"
    end

    def inspect
      "#{@class_name}:#{@parse_object_id} #{super}"
    end

    # Update the fields of the local Parse object with the current
    # values from the API.
    def refresh
      if @parse_object_id
        data = RestClient.get(@class_name, @parse_object_id, @client)
        @op_fields = {}
        clear
        parse data if data
      end

      self
    end

    # Delete the remote Parse API object.
    def parse_delete
      @client.delete uri if @parse_object_id

      clear
      self
    end

    def array_add(field, value)
      array_op(field, Protocol::KEY_ADD, value)
    end

    def array_add_relation(field, value)
      array_op(field, Protocol::KEY_ADD_RELATION, value)
    end

    def array_remove_relation(field, value)
      array_op(field, Protocol::KEY_REMOVE_RELATION, value)
    end

    def array_add_unique(field, value)
      array_op(field, Protocol::KEY_ADD_UNIQUE, value)
    end

    def array_remove(field, value)
      array_op(field, Protocol::KEY_REMOVE, value)
    end

    # Increment the given field by an amount, which defaults to 1.
    # Saves immediately to reflect incremented
    def increment(field, amount = 1)
      # value = (self[field] || 0) + amount
      # self[field] = value
      # if !@parse_object_id
      #  # TODO - warn that the object must be stored first
      #  return nil
      # end

      body = {field => RestClient::Increment.new(amount)}.to_json
      data = @client.request(uri, :put, body)
      parse data
      self
    end

    # Decrement the given field by an amount, which defaults to 1.
    # Saves immediately to reflect decremented
    # A synonym for increment(field, -amount).
    def decrement(field, amount = 1)
      increment(field, -amount)
    end

    private

    # Merge a hash parsed from the JSON representation into
    # this instance. This will extract the reserved fields,
    # merge the hash keys, and then ensure that the reserved
    # fields do not occur in the underlying hash storage.
    def parse(data)
      return unless data

      @parse_object_id ||= data[Protocol::KEY_OBJECT_ID]

      if data.key? Protocol::KEY_CREATED_AT
        @created_at = DateTime.parse data[Protocol::KEY_CREATED_AT]
      end

      if data.key? Protocol::KEY_UPDATED_AT
        @updated_at = DateTime.parse data[Protocol::KEY_UPDATED_AT]
      end

      data.each do |k, v|
        k = k.to_s if k.is_a? Symbol

        self[k] = v if k != RestClient::Protocol::KEY_TYPE
      end

      self
    end

    def array_op(field, operation, value)
      error_msg = "field #{field} not an array"
      raise error_msg if self[field] && !self[field].is_a?(Array)

      if @parse_object_id
        @op_fields[field] ||= ArrayOp.new(operation, [])
        error_msg = "only one operation type allowed per array #{field}"
        raise error_msg if @op_fields[field].operation != operation
        @op_fields[field].objects << RestClient.pointerize_value(value)
      end

      # parse doesn't return column values on initial POST creation so
      # we must maintain them ourselves
      case operation
        when Protocol::KEY_ADD, Protocol::KEY_ADD_RELATION
          self[field] ||= []
          self[field] << value
        when Protocol::KEY_ADD_UNIQUE
          self[field] ||= []
          self[field] << value unless self[field].include?(value)
        when Protocol::KEY_REMOVE, Protocol::KEY_REMOVE_RELATION
          self[field].delete(value) if self[field]
      end
    end
  end
end