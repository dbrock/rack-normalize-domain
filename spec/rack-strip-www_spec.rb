require 'rack-strip-www'

describe "Rack::StripWWW" do
  def strip_www host
    Rack::StripWWW.strip_www host
  end

  it "should work" do
    strip_www("example.com").
      should == "example.com"
    strip_www("www.example.com").
      should == "example.com"
    strip_www("www.example.co.uk").
      should == "example.co.uk"
    strip_www("www.subdomain.example.co.uk").
      should == "www.subdomain.example.co.uk"
    strip_www("www.com").
      should == "www.com"
  end
end
