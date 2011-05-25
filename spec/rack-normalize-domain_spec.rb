require 'rack/normalize-domain'
require 'rack/test'
require 'uri'

describe Rack::NormalizeDomain do
  include Rack::Test::Methods

  it "should strip www properly" do
    normalizer :strip_www

    should_redirect \
      'http://www.example.com' => 'http://example.com',
      'https://www.example.com' => 'https://example.com',
      'http://www.example.co.uk' => 'http://example.co.uk',
      'http://www.x.example.co.uk' => 'http://x.example.co.uk',
      'http://www.example.com/foo' => 'http://example.com/foo',
      'http://www.example.com/foo?bar=baz' => 'http://example.com/foo?bar=baz'

    should_not_redirect \
      'http://example.com',
      'https://x.example.co.uk/foo?bar=baz'
  end

  it "should strip www by default" do
    normalizer :strip_www
    should_redirect \
      'http://www.example.com' => 'http://example.com'
    should_not_redirect \
      'http://example.com'
  end

  it "should apply custom normalizer" do
    normalizer :strip_www do |host| "#{host}.foo" end
    should_redirect \
      'http://www.example.com/bar' => 'http://example.com.foo/bar'
  end

  it "should not redirect hostless requests" do
    normalizer :strip_www
    get('/')
    last_response.status.should == 200
  end

  it "should not redirect POST requests" do
    normalizer :strip_www
    post_url('http://www.example.com')
    last_response.status.should == 200
  end

  def should_redirect(mappings)
    for source, expected_destination in mappings
      get_url(source)
      last_response.status.should == 301
      last_response['Location'].should == expected_destination
    end
  end

  def should_not_redirect(*sources)
    for source in sources
      get_url(source)
      last_response.status.should == 200
    end
  end

  def get_url(url)
    request_url :get, url
  end

  def post_url(url)
    request_url :post, url
  end

  def request_url(method, url)
    url = URI.parse(url)
    send method,
      url.path,
      get_query_params(url.query),
      'HTTP_HOST' => url.host,
      'rack.url_scheme' => url.scheme
  end

  it "should have correct get_query_params in specification" do
    get_query_params('foo=bar&baz=quux').
      should == { 'foo' => 'bar', 'baz' => 'quux' }
  end

  def get_query_params(query)
    query ? Hash[query.split('&').map { |x| x.split('=') }] : {}
  end

  def normalizer(value=nil, &block)
    @normalizer_value = value
    @normalizer_block = block
  end

  def app
    app = Rack::Builder.new
    app.use Rack::NormalizeDomain, @normalizer_value, &@normalizer_block
    app.run lambda { [200, { 'Content-Type ' => 'text/plain' }, ''] }
    app
  end
end
