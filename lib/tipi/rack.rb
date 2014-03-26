require 'json'
require 'uri'

module Tipi
  class Rack
    def initialize(service)
      @service = service
      @matcher = service.matcher
      @invokers = Hash.new { |h, k| h[k] = invoker_for(*k) }
    end

    def call(env)
      path = env['PATH_INFO']
      verb = env['REQUEST_METHOD'].to_sym
      obj = @service.root
      resource = obj.class

      res = @matcher.match(resource, verb, path)
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
        extra_args << parse_query(env, keys) if keys
        obj.send(target, *args, *extra_args)
      end
    end

    def parse_body(env)
      JSON.parse(env['rack.input'].read)
    end

    def parse_query(env, keys)
      res = {}
      env['QUERY_STRING'].split('&').each do |part|
        key, value = part.split('=', 2)
        if keys.include?(key)
          value = URI.decode_www_form_component(value)
          res[key.to_sym] = value
        end
      end
      res
    end

    def respond(obj)
      str = obj.to_json
      [200,{'Content-Type'=>'application/json'},[str]]
    end

    def not_found
      [404,{'Content-Type'=>'application/json'},[]]
    end
  end
end

