require_relative 'helper'
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

    it "inherits Finitio systems" do
      main = Class.new(Resource) do
        import "Hash = .Hash"
      end

      sub = Class.new(main)
      assert sub.system['Hash']
    end

    it "can import Finitio strings" do
      sub = Class.new(Resource) do
        import "Hash = .Hash"

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
  end
end

