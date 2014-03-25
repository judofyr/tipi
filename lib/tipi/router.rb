module Tipi
  class Router
    def initialize(&blk)
      @resources = {}
      instance_eval &blk if blk
    end

    def resource(klass, &blk)
      res = (@resources[klass] ||= ResourceRoute.new(self, klass))
      res.instance_eval(&blk) if blk
      res
    end

    class Builder
      attr_reader :verb
      def initialize(path, verb)
        @path = path
        @verb = verb
      end

      def path
        @path || "/".freeze
      end

      def to_s
        path
      end
    end

    class ResourceRoute
      attr_reader :klass, :routes, :builder_class

      def initialize(router, klass)
        @router = router
        @klass = klass
        @builder_class = Class.new(Builder)
        @routes = []
      end

      def builder
        @builder_class.new(nil, nil)
      end

      def add_route
        route = Route.new
        yield route
        route.define_builder(@builder_class, @router)
        @routes << route
        self
      end

      def action(verb, pattern = nil, to:)
        add_route do |route|
          route.verb = verb
          route.target = to
          route.pattern = pattern
        end
      end

      def path(pattern, to:, returns:)
        add_route do |route|
          route.target = to
          route.pattern = pattern
          route.resource = returns
        end
      end
    end

    EMPTY = [].freeze

    class Route
      attr_accessor :verb, :target, :pattern, :resource

      def pattern=(pattern)
        @pattern = pattern
        if pattern
          @parts = pattern.split(/[{}]/)
          @prefix = @parts.first
          compile_pattern
        else
          @parts = nil
          @prefix = nil
          @builder = nil
          @regexp = nil
        end
      end

      def endpoint?
        @verb
      end

      UNRESERVED = /[\w\-.~]/

      def compile_pattern
        builder = ""
        regexp = '\A'
        @parts.each_slice(2) do |static, pattern_name|
          builder << static.gsub("%", "%%")
          regexp << Regexp.escape(static)
          if pattern_name
            if pattern_name !~ /\A\w*\z/
              raise ArgumentError, "Unsupported URI template pattern: {#{pattern_name}}"
            end
            builder << "%s"
            regexp << "(#{UNRESERVED}+)"
          end
        end
        @builder = builder
        @regexp = Regexp.new(regexp)
      end

      def match_path(path)
        if @pattern.nil?
          return unless path.empty?
          # Successful match
          return EMPTY, "".freeze
        end

        # Quickly check if it can match at all
        return if !path.start_with?(@prefix)
        return unless md = @regexp.match(path)
        return md.captures, md.post_match
      end

      def define_builder(builder_class, router)
        builder = @builder
        verb = @verb
        resource = @resource
        if resource
          next_builder_class = router.resource(resource).builder_class
        else
          next_builder_class = Builder
        end

        builder_class.send(:define_method, target) do |*args|
          if builder
            path_segment = builder % args
            path = @path ? @path + path_segment : path_segment
          end
          next_builder_class.new(path || @path, verb)
        end
      end
    end

    def finalize
      # TODO: Freeze?
      self
    end

    def match(resource, verb, path)
      res = []

      path = "".freeze if path == "/".freeze

      while true
        routes = @resources.fetch(resource).routes
        captures = nil

        routes.each do |route|
          next if route.verb && route.verb != verb
          captures, rest_path = route.match_path(path)
          if captures
            res << [resource, route.target, captures]
            return res if route.endpoint? && rest_path.empty?
            resource = route.resource
            return EMPTY unless resource
            path = rest_path
            break
          end
        end

        return EMPTY if !captures
      end
    end
  end
end

