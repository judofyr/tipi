require_relative 'helper'
require 'tipi'

describe Tipi::Redirect do
  describe "#to_response" do
    it "returns redirect" do
      redirect = Tipi::Redirect.new("http://www.vg.no/")
      status, headers, body = redirect.to_response
      assert_equal 302, status
      assert_equal "http://www.vg.no/", headers['Location']
    end
  end
end

describe Tipi::TypeError do
  describe "#build" do
    it "works" do
      ex = Tipi::TypeError.build(
        message: "Name required",
        location: "users/1",
        resource: Tipi,
        method_name: :update,
        data: {users:[{name:"Bob"},{}]}
      )

      assert_equal "(Tipi#update) users/1: Name required in {:users=>[{:name=>\"Bob\"}, {}]}", ex.message
      assert_equal "users/1", ex.location
      assert_equal Tipi, ex.resource
      assert_equal :update, ex.method_name
      assert_equal "Name required", ex.short_message
    end
  end
end

