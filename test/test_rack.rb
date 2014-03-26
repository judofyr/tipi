require_relative 'helper'
require 'tipi/rack'
require 'tipi/router'
require 'tipi/resource'
require 'rack'

module Tipi
  module TestRack
    describe Rack do
      class Root < Resource
        def index
          { name: "Hello" }
        end

        option_keys :a
        def params(options = {})
          options
        end

        def users
          Users.new(state)
        end
      end

      class Users < Resource
        option_keys :page
        def list(options = {})
          if options[:page] == "2"
            [{name: "Bob"}]
          else
            [{name: "Rob"}]
          end
        end

        def [](id)
          state[:id] = id.to_i
          User.new(state)
        end
      end

      class User < Resource
        def info
          { id: state[:id] }
        end

        input "{ name: String }"
        def update(data)
          data
        end
      end

      class Service
        ROUTER = Router.new do
          resource Root do
            action :GET, to: 'index'
            action :GET, '/params', to: 'params'
            path '/users', to: 'users', returns: Users
          end

          resource Users do
            action :GET, to: 'list'
            path '/{id}', to: '[]', returns: User
          end

          resource User do
            action :GET, to: 'info'
            action :POST, to: 'update'
          end
        end

        def self.matcher
          ROUTER.finalize
        end

        def self.root
          Root.new({})
        end
      end

      let(:router) do
      end

      let(:app) do
        Rack.new(Service)
      end

      let(:mock_request) do
        ::Rack::MockRequest.new(app)
      end

      it "handles basic action" do
        res = mock_request.get('/')
        assert_equal 200, res.status
        assert_equal '{"name":"Hello"}', res.body
      end

      it "returns 404 on unknown resources" do
        res = mock_request.get('/foobar')
        assert_equal 404, res.status
      end

      it "can follow sub resources" do
        res = mock_request.get('/users/123')
        assert_equal 200, res.status
        assert_equal '{"id":123}', res.body
      end

      it "handles query params" do
        res = mock_request.get('/users')
        assert_equal 200, res.status
        assert_equal '[{"name":"Rob"}]', res.body

        res = mock_request.get('/users?page=2')
        assert_equal 200, res.status
        assert_equal '[{"name":"Bob"}]', res.body

        res = mock_request.get('/params?a=%2F')
        assert_equal 200, res.status
        assert_equal '{"a":"/"}', res.body
      end

      it "handles post body" do
        res = mock_request.post('/users/123', input: '{"name":"Bob"}')
        assert_equal 200, res.status
        assert_equal '{"name":"Bob"}', res.body
      end
    end
  end
end

