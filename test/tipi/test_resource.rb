require_relative '../helper'
require 'tipi/resource'

module Tipi
  describe Resource do
    it "maintains state" do
      res = Resource.new({})
      res.state[:a] = 1
      assert_equal({a: 1}, res.state)
    end

    it "handles input validation" do
      sub = Class.new(Resource) do
        input "{ name: String }"
        def update(data)
          true
        end
      end

      res = sub.new({})
      assert_raises(Finitio::TypeError) do
        res.update({})
      end

      assert res.update(name: "Bob")
    end

    it "handles output validation" do
      sub = Class.new(Resource) do
        output "{ name: String }"
        def update(data)
          data
        end
      end

      res = sub.new({})
      assert_raises(Finitio::TypeError) do
        res.update({})
      end

      assert res.update(name: "Bob")
    end

    it "inherits Finitio systems" do
      main = Class.new(Resource) do
        parse_system "Hash = .Hash"
      end

      sub = Class.new(main)
      assert sub.system['Hash']
    end

    it "can import Finitio strings" do
      sub = Class.new(Resource) do
        parse_system "Hash = .Hash"

        input "Hash"
        def update(foo)
          true
        end
      end

      res = sub.new({})
      assert_raises(Finitio::TypeError) do
        res.update(123)
      end

      assert res.update(name: "Bob")
    end

    it "stores information about methods" do
      sub = Class.new(Resource) do
        input "{ name: String }"
        output "{ status: String }"
        stability :stable
        option_keys :page
        def list
        end
      end

      assert info = sub.action_info(:list)
      assert info.frozen?
      assert info.input_type
      assert info.output_type
      assert_equal :stable, info.stability
      assert_equal [:page], info.option_keys
    end

    it "can redirect" do
      res = Resource.new({})
      redirect = res.redirect_response("http://vg.no/")
      assert_instance_of Redirect, redirect
    end

    it "can raise not found" do
      res = Resource.new({})
      assert_raises NotFound do
        res.raise_not_found
      end
    end

    describe "resource with custom tuple class" do
      let(:resource_class) do
        Class.new(Resource) do
          parse_system "ShortURL = { id: String, url: String }"
        end
      end

      let(:short_url_class) do
        resource_class.AutoTuple :ShortURL
      end

      before do
        # Ensure this has been loaded
        short_url_class
      end

      it "defines accessors" do
        obj = short_url_class.new(id: "123", url: "http://example.com/")
        assert_equal "123", obj.id
        assert_equal "http://example.com/", obj.url
      end

      it "coerces actions" do
        resource_class.class_eval do
          input "ShortURL"
          def update(data)
            data
          end
        end

        res = resource_class.new({})
        obj = res.update(id: "123", url: "http://example.com/")
        assert_instance_of short_url_class, obj
        assert_equal "123", obj.id
        assert_equal "http://example.com/", obj.url
      end

      it "provides #dress on the tuple class" do
        assert_raises Finitio::TypeError do
          short_url_class.dress(id: 123)
        end

        assert_instance_of short_url_class, short_url_class.dress(id: "123", url: "http://example.com/")
      end
    end
  end
end

