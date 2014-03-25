require 'finitio'

module Tipi
  class Resource
    attr_reader :state

    def initialize(state)
      @state = state
    end

    def self.system
      return @system if defined? @system

      if Resource === superclass
        @system = superclass.system
      else
        @system = Finitio::DEFAULT_SYSTEM
      end
    end

    def self.import(str)
      @system = system.parse(str)
    end

    def self.input(str)
      @input_type = system.parse(str)
    end
    
    def self.method_added(name)
      input_type = @input_type
      @input_type = nil

      if input_type
        orig = instance_method(name)
        define_method(name) do |*args|
          args[0] = input_type.dress(args[0])
          orig.bind(self).call(*args)
        end
      end
    end
  end
end

