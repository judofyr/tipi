require_relative '../helper'
require 'tipi/router'

module Tipi
  describe Router do
    foo = Class.new
    bar = Class.new

    it "supports block parameter" do
      scope = nil
      Router.new do
        scope = self
      end
      assert_instance_of Router, scope
    end

    let(:router) do
      Router.new
    end

    it "re-uses resource routes" do
      a = router.resource(foo)
      b = router.resource(foo)
      assert_equal a.object_id, b.object_id
    end

    let(:foo_resource) do
      router.resource(foo)
    end

    let(:bar_resource) do
      router.resource(bar)
    end

    let(:foo_builder) do
      foo_resource.builder
    end

    let(:matcher) do
      router.finalize
    end

    it "reports when you use unsupported URI template" do
      assert_raises(ArgumentError) do
        foo_resource.action(:GET, '{/path}', to: 'path')
      end
    end

    it "#action requires :to" do
      res = assert_raises(ArgumentError) do
        foo_resource.action(:GET)
      end
      assert_match /:to/, res.message
      assert_match /#action/, res.message
    end

    it "#path requires :to" do
      res = assert_raises(ArgumentError) do
        foo_resource.path('/bob', returns: 123)
      end
      assert_match /:to/, res.message
      assert_match /#path/, res.message
    end

    it "#path requires :returns" do
      res = assert_raises(ArgumentError) do
        foo_resource.path('/bob', to: 'bob')
      end
      assert_match /:returns/, res.message
      assert_match /#path/, res.message
    end

    describe "with basic actions" do
      before do
        foo_resource.action(:GET, to: 'index')
        foo_resource.action(:GET, '/info', to: 'info')
        foo_resource.action(:GET, '/{username}', to: 'user')
      end

      it "matches empty pattern" do
        result = matcher.match(foo, :GET, '/')
        assert_equal [[foo, 'index', []]], result

        result = matcher.match(foo, :GET, '')
        assert_equal [[foo, 'index', []]], result
      end

      it "matches static pattern" do
        result = matcher.match(foo, :GET, '/info')
        assert_equal [[foo, 'info', []]], result
      end

      it "only matches full paths" do
        result = matcher.match(foo, :GET, '/info/bib')
        assert_equal [], result
      end

      it "matches dynamic pattern" do
        result = matcher.match(foo, :GET, '/bob')
        assert_equal [[foo, 'user', ['bob']]], result
      end

      it "respects the verb" do
        result = matcher.match(foo, :POST, '/bob')
        assert_equal [], result
      end

      it "can build static URLs" do
        assert_equal "/", foo_builder.index.to_s
        assert_equal :GET, foo_builder.index.verb

        assert_equal "/info", foo_builder.info.to_s
        assert_equal :GET, foo_builder.info.verb
      end

      it "can build dynamic URLs" do
        assert_equal "/bob", foo_builder.user("bob").to_s
      end
    end

    describe "with nested paths" do
      before do
        foo_resource.action(:GET, '/info', to: 'info')
        foo_resource.path('/bar', to: 'bar', returns: bar)
        bar_resource.action(:GET, to: 'index')
        bar_resource.action(:GET, '/info', to: 'info')
      end

      it "still matches top-level" do
        result = matcher.match(foo, :GET, '/info')
        assert_equal [[foo, 'info', []]], result
      end

      it "can match directly into another resource" do
        result = matcher.match(bar, :GET, '/info')
        assert_equal [[bar, 'info', []]], result
      end

      it "can match a resource through another" do
        result = matcher.match(foo, :GET, '/bar/info')
        assert_equal [[foo, 'bar', []], [bar, 'info', []]], result
      end

      it "can build URLs across resources" do
        assert_equal "/bar", foo_builder.bar.index.to_s
        assert_equal "/bar/info", foo_builder.bar.info.to_s
      end
    end
  end
end

