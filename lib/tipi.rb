module Tipi
  class NotFound < StandardError
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

