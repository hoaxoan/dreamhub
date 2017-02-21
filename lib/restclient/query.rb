# encoding: utf-8
module RestClient
  # Query objects
  # https://parse.com/docs/rest/guide/#queries
  class Query
    attr_accessor :where
    attr_accessor :class_name
    attr_accessor :order_by
    attr_accessor :order
    attr_accessor :limit
    attr_accessor :skip
    attr_accessor :count
    attr_accessor :include
    attr_accessor :client
    attr_accessor :keys

    def initialize(cls_name, client = nil)
      @class_name = cls_name
      @where = {}
      @order = :ascending
      @ors = []
      @client = client || RestClient.client
    end

    def add_constraint(field, constraint)
      raise ArgumentError, 'cannot add constraint to an $or query' unless @ors.empty?
      current = where[field]
      if current && current.is_a?(Hash) && constraint.is_a?(Hash)
        current.merge! constraint
      else
        where[field] = constraint
      end
    end

    def or(query)
      raise ArgumentError, "you must pass an entire #{self.class} to \#or" unless query.is_a?(self.class)
      @ors << query
      self
    end

    def eq(hash_or_field, value = nil)
      return eq_pair(hash_or_field, value) unless hash_or_field.is_a?(Hash)

      hash_or_field.each_pair { |k, v| eq_pair k, v }
      self
    end

    def not_eq(field, value)
      add_constraint field, '$ne' => RestClient.pointerize_value(value)
      self
    end

    def regex(field, expression)
      add_constraint field, '$regex' => expression
      self
    end

    def less_than(field, value)
      add_constraint field, '$lt' => RestClient.pointerize_value(value)
      self
    end

    def less_eq(field, value)
      add_constraint field, '$lte' => RestClient.pointerize_value(value)
      self
    end

    def greater_than(field, value)
      add_constraint field, '$gt' => RestClient.pointerize_value(value)
      self
    end

    def greater_eq(field, value)
      add_constraint field, '$gte' => RestClient.pointerize_value(value)
      self
    end

    def value_in(field, values)
      add_constraint(
          field, '$in' => values.map { |v| RestClient.pointerize_value(v) })
      self
    end

    def value_not_in(field, values)
      add_constraint(
          field, '$nin' => values.map { |v| RestClient.pointerize_value(v) })
      self
    end

    def contains_all(field, values)
      add_constraint(
          field, '$all' => values.map { |v| RestClient.pointerize_value(v) })
      self
    end

    def related_to(field, value)
      h = {'object' => RestClient.pointerize_value(value), 'key' => field}
      add_constraint('$relatedTo', h)
    end

    def exists(field, value = true)
      add_constraint field, '$exists' => value
      self
    end

    def in_query(field, query = nil)
      query_hash = {
          RestClient::Protocol::KEY_CLASS_NAME => query.class_name,
          'where' => query.where}
      add_constraint(field, '$inQuery' => query_hash)
      self
    end

    def count
      @count = true
      self
    end

    def where_as_json
      if @ors.empty?
        @where
      else
        {'$or' => [where] + @ors.map(&:where_as_json)}
      end
    end

    def first
      self.limit = 1
      get.first
    end

    def get
      uri = if @class_name == RestClient::Protocol::CLASS_USER
              Protocol.user_uri
            elsif @class_name == RestClient::Protocol::CLASS_INSTALLATION
              Protocol.installation_uri
            else
              Protocol.class_uri @class_name
            end

      query = {'where' => where_as_json.to_json}
      ordering(query)

      [:count, :limit, :skip, :include, :keys].each do |a|
        merge_attribute(a, query)
      end
      @client.logger.info { "Parse query for #{uri} #{query.inspect}" } unless @client.quiet
      response = @client.request uri, :get, nil, query

      if response.is_a?(Hash) && response.key?(Protocol::KEY_RESULTS) && response[Protocol::KEY_RESULTS].is_a?(Array)
        parsed_results = response[Protocol::KEY_RESULTS].map do |result|
          result = RestClient.parse_json(class_name, result)
          RestClient.copy_client(@client, result)
        end

        if response.keys.size == 1
          parsed_results
        else
          response.dup.merge(Protocol::KEY_RESULTS => parsed_results)
        end
      else
        raise RestClientError, "query response not a Hash with #{Protocol::KEY_RESULTS} key: #{response.class} #{response.inspect}"
      end
    end

    private

    def eq_pair(field, value)
      add_constraint field, RestClient.pointerize_value(value)
      self
    end

    def ordering(query)
      return unless @order_by
      order_string = @order_by
      order_string = "-#{order_string}" if @order == :descending
      query[:order] = order_string
    end

    def merge_attribute(attribute, query, query_field = nil)
      value = instance_variable_get("@#{attribute}")
      return if value.nil?
      to_merge = query_field || attribute
      query[to_merge] = value
    end
  end
end
