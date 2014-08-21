require 'tipi'
require 'finitio'

module Tipi


  class Resource
    attr_reader :state

    def initialize(state)
      @state = state
    end

    def raise_not_found(msg = nil)
      raise NotFound, msg
    end

    def redirect_response(*args)
      Redirect.new(*args)
    end

    def self.system
      return @system if defined? @system

      if self == Resource
        @system = Finitio::DEFAULT_SYSTEM
      else
        @system = superclass.system
      end
    end

    def self.parse_system(str)
      @system = system.parse(str)
    end

    class ActionInfo
      attr_accessor :input_type, :output_type, :option_keys, :stability

      def decorate(klass, name)
        input_type = self.input_type
        output_type = self.output_type
        return if input_type.nil? && output_type.nil?

        orig = klass.instance_method(name)
        klass.send(:define_method, name) do |*args|
          begin
            args[0] = input_type.dress(args[0]) if input_type && args.size > 0
          rescue Finitio::TypeError => ex
            raise Tipi::TypeError.new("Invalid input #{args[0]} for #{klass} (#{ex})")
          end
          res = orig.bind(self).call(*args)
          res = output_type.dress(res) if output_type
          res
        end
      end
    end

    def self.current_action_info
      @current_action_info ||= ActionInfo.new
    end

    def self.action_infos
      @action_infos ||= {}
    end

    def self.action_info(name)
      action_infos[name]
    end

    def self.input(str)
      current_action_info.input_type = system.parse(str)
    end

    def self.output(str)
      current_action_info.output_type = system.parse(str)
    end

    def self.option_keys(*list)
      current_action_info.option_keys = list
    end

    def self.stability(stability)
      current_action_info.stability = stability
    end

    def self.method_added(name)
      if action_info = @current_action_info
        @current_action_info = nil
        action_infos[name] = action_info
        action_info.decorate(self, name)
        action_info.freeze
      end
    end
  end

  class TypeError < StandardError
  end
end
