$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'tipi'

module TeenyURL
  ## The servic encapsulate everything needed to access this API
  class Service
    attr_reader :urls

    def initialize
      @urls = {}
    end

    ## This is our entry point
    def root
      Root.new(service: self)
    end

    ## We use these to generate random-ish URLs
    ALPHABET = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
    ALPHABET.shuffle!
    def next_id
      numid = urls.size + 1
      id = ""
      while numid > 0
        numid, offset = numid.divmod(ALPHABET.size)
        id << ALPHABET[offset]
      end
      id
    end
  end

  ## Setup a base class for all our Resources
  class Resource < Tipi::Resource
    import <<-EOF
      ShortURL = { id: String, url: String }
    EOF

    def service
      state[:service]
    end
  end

  ## Entry point
  class Root < Resource
    input "{ url: String }"
    output "ShortURL"
    def create(data)
      id = service.next_id
      service.urls[id] = data[:url]
      { id: id, url: data[:url] }
    end

    def url(id)
      url = state[:service].urls[id]
      raise_not_found unless url

      state[:id] = id
      state[:url] = url
      URL.new(state)
    end
  end

  ## A single URL. Instantiate this through Root#url
  class URL < Resource
    output "ShortURL"
    def lookup
      { id: state[:id], url: state[:url] }
    end

    def redirect
      redirect_response(state[:url])
    end
  end

  ## The router hooks everything up
  ROUTER = Tipi::Router.new do
    resource Root do
      path '/urls/{id}', to: 'url', returns: URL
      action :POST, '/urls', to: 'create'
    end

    resource URL do
      action :GET, to: 'lookup'
      action :GET, '/redirect', to: 'redirect'
    end
  end

end

require 'rack'

service = TeenyURL::Service.new

# Add a default URLs
p service.root.create(url: "http://ruby-lang.org/")

app = Tipi::Rack.new(service, TeenyURL::ROUTER)
Rack::Server.start(app: app, Port: 5678)

