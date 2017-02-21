# encoding: utf-8
module RestClient
  # A module which encapsulates the specifics of Parse's REST API.
  module Protocol
    # Basics
    # ----------------------------------------

    # The default hostname and path for communication with the Parse API.
    HOST            = 'http://localhost:8011/'
    PATH            = '/booked/Web/Services/index.php'

    # HTTP Headers
    # ----------------------------------------

    # The HTTP header used for passing your API Master key to the
    # Parse API.
    HEADER_USER_ID = 'X-Booked-UserId'

    # The HTTP header used for passing your authenticated session
    HEADER_SESSION_TOKEN = 'X-Booked-SessionToken' #'X-Parse-Session-Token'

    # JSON Keys
    # ----------------------------------------

    # The JSON key used to store the class name of an object
    # in a Pointer datatype.
    KEY_CLASS_NAME  = 'className'

    # The JSON key used to store the ID of Parse objects
    # in their JSON representation.
    KEY_OBJECT_ID   = 'id'

    # The JSON key used to store the creation timestamp of
    # Parse objects in their JSON representation.
    KEY_CREATED_AT  = 'createdAt'

    # The JSON key used to store the last modified timestamp
    # of Parse objects in their JSON representation.
    KEY_UPDATED_AT  = 'updatedAt'

    KEY_USER_SESSION_TOKEN = 'sessionToken'

    KEY_USER_ID = 'userId'

    # The JSON key used in the top-level response object
    # to indicate that the response contains an array of objects.
    RESPONSE_KEY_RESULTS = 'results'
    KEY_RESULTS = RESPONSE_KEY_RESULTS

    # The JSON key used to identify an operator
    KEY_OP          = '__op'

    KEY_INCREMENT   = 'Increment'
    KEY_DELETE      = 'Delete'

    # array ops
    KEY_OBJECTS         = 'objects'
    KEY_ADD             = 'Add'
    KEY_ADD_RELATION    = 'AddRelation'
    KEY_REMOVE_RELATION = 'RemoveRelation'
    KEY_ADD_UNIQUE      = 'AddUnique'
    KEY_REMOVE          = 'Remove'

    DELETE_OP       = { KEY_OP => KEY_DELETE }

    # The JSON key used to identify the datatype of a special value.
    KEY_TYPE        = '__type'

    # The JSON key used to specify the numerical value in the
    # increment/decrement API call.
    KEY_AMOUNT      = 'amount'

    RESERVED_KEYS = [
        KEY_CLASS_NAME, KEY_CREATED_AT, KEY_OBJECT_ID,
        KEY_UPDATED_AT, KEY_USER_SESSION_TOKEN]

    # Other Constants
    # ----------------------------------------

    # The class name for User objects.
    CLASS_USER      = 'user'

    # The class name for Resource objects.
    CLASS_RESOURCE      = 'resource'

    # The class name for Reservation objects.
    CLASS_RESERVATION      = 'reservation'

    # The class name for Accessory objects.
    CLASS_ACCESSORY      = 'accessory'

    # Operation name for incrementing an objects field value remotely
    OP_INCREMENT    = 'Increment'

    # The data type name for special JSON objects representing a full object
    TYPE_OBJECT     = 'Object'

    # The data type name for special JSON objects representing a reference
    # to another Parse object.
    TYPE_POINTER    = 'Pointer'

    # The data type name for special JSON objects containing an array of
    # encoded bytes.
    TYPE_BYTES      = 'Bytes'

    # The data type name for special JSON objects representing a date/time.
    TYPE_DATE       = 'Date'

    # The data type name for special JSON objects representing a
    # location specified as a latitude/longitude pair.
    TYPE_GEOPOINT   = 'GeoPoint'

    # The data type name for special JSON objects representing
    # a file.
    TYPE_FILE       = 'File'

    # The data type name for special JSON objects representing
    # a Relation.
    TYPE_RELATION   = 'Relation'



    CLASS_INSTALLATION = '_Installation'

    USER_LOGIN_URI = '/Authentication/Authenticate'
    PASSWORD_RESET_URI = '/requestPasswordReset'

    CLOUD_FUNCTIONS_PATH = 'functions'

    BATCH_REQUEST_URI = 'batch'

    ERROR_INTERNAL = 1
    ERROR_TIMEOUT = 124
    ERROR_EXCEEDED_BURST_LIMIT = 155
    ERROR_OBJECT_NOT_FOUND_FOR_GET = 101

    # URI Helpers
    # ----------------------------------------

    # Construct a uri referencing a given Parse object
    # class or instance (of object_id is non-nil).
    def self.class_uri(class_name, object_id = nil)
      if object_id
        "/classes/#{class_name}/#{object_id}"
      else
        "/classes/#{class_name}"
      end
    end


    # Construct a uri referencing a given Parse user
    # instance or the users category.
    def self.user_uri(user_id = nil)
      if user_id
        "/Users/#{user_id}"
      else
        '/Users/'
      end
    end

    # Construct a uri referencing a given Parse resource
    # instance or the resources category.
    def self.resource_uri(resource_id = nil)
      if resource_id
        "/Resources/#{resource_id}"
      else
        '/Resources/'
      end
    end

    # Construct a uri referencing a given Parse reservation
    # instance or the reservations category.
    def self.reservation_uri(reservation_id = nil)
      if reservation_id
        "/Reservations/#{reservation_id}"
      else
        '/Reservations/'
      end
    end

    # Construct a uri referencing a given Parse reservation
    # instance or the accessory category.
    def self.accessory_uri(accessory_id = nil)
      if accessory_id
        "/Accessories/#{accessory_id}"
      else
        '/Accessories/'
      end
    end


  end
end