require 'json'
require 'uri'

module Tipi
  class Rack
    def initialize(service)
      @service = service
      @invokers = Hash.new { |h, k| h[k] = invoker_for(*k) }
    end

    def call(env)
      path = env['PATH_INFO']
      verb = env['REQUEST_METHOD'].to_sym
      obj = @service.root
      resource = obj.class

      res = @service.match(resource, verb, path)
      return not_found if res.empty?

      res.each do |resource, target, args|
        invoker = @invokers[[resource, target]]
        obj = invoker.call(env, obj, args)
      end
      respond(obj)
    end

    def invoker_for(resource, target)
      info = resource.action_info(target.to_sym) if resource.respond_to?(:action_info)
      keys = info && info.option_keys && info.option_keys.map(&:to_s)
      has_input = info && info.input_type

      proc do |env, obj, args|
        extra_args = []
        extra_args << parse_body(env) if has_input
        extra_args << parse_query(env['QUERY_STRING'], keys) if keys
        obj.send(target, *args, *extra_args)
      end
    end

    JSON_TYPE = 'application/json'.freeze

    def parse_body(env)
      case env['CONTENT_TYPE']
      when 'application/x-www-form-urlencoded'
        parse_query(env['rack.input'].read, nil)
      when JSON_TYPE
        JSON.parse(env['rack.input'].read)
      end
    end

    def parse_query(str, keys)
      res = {}
      str.split('&').each do |part|
        key, value = part.split('=', 2)
        if keys.nil? || keys.include?(key)
          value = URI.decode_www_form_component(value)
          res[key.to_sym] = value
        end
      end
      res
    end

    def respond(obj)
      if obj.respond_to?(:to_response)
        obj.to_response
      else
        str = obj.to_json
        [200,{'Content-Type'=>JSON_TYPE},[str]]
      end
    end

    def not_found
      [404,{'Content-Type'=>JSON_TYPE},[]]
    end
  end
end

