module Tipi
  class NotFound < StandardError
  end

  class TypeError < StandardError
    attr_accessor :short_message, :resource, :method_name, :data, :location

    def self.build(message:, location:, resource:, method_name:, data:)
      ex = new("(#{resource}##{method_name}) #{location}: #{message} in #{data.inspect}")
      ex.short_message = message
      ex.location = location
      ex.resource = resource
      ex.method_name = method_name
      ex.data = data
      ex
    end
  end

  class Redirect
    def initialize(url)
      @url = url
    end

    def to_response
      [302,{'Location'=>@url},[]]
    end
  end

  autoload :Router, 'tipi/router'
  autoload :Resource , 'tipi/resource'
  autoload :Rack, 'tipi/rack'
end

