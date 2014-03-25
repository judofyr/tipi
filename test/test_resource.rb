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
  end
end

