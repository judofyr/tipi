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

