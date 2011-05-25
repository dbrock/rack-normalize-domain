require 'rack'
require 'uri'

class Rack::NormalizeDomain
  def initialize(app, canned_strategy=nil, &block)
    @app = app
    @normalizer = get_normalizer(canned_strategy, block)
  end

  def get_normalizer(canned_strategy, block)
    canned_normalizer = get_canned_normalizer(canned_strategy)
    custom_normalizer = block || lambda { |host| host }

    lambda { |host| custom_normalizer[canned_normalizer[host]] }
  end

  def get_canned_normalizer(strategy)
    case strategy
    when nil, :strip_www
      lambda { |host| host.sub(/^www\./, '') }
    else
      fail "Unknown strategy: #{strategy}"
    end
  end

  def call(env)
    request = Request.new(@normalizer, env)

    if request.needs_normalization?
      [301, { 'Location' => request.normalized_url }, '']
    else
      @app.call(env)
    end
  end

  class Request
    def initialize(normalizer, env)
      @normalizer = normalizer
      @env = env
    end

    def needs_normalization?
      http_get? and not already_normalized?
    end

    def normalized_url
      "#{scheme}://#{normalized_host}#{path}#{query}"
    end

    def already_normalized?; host == normalized_host end
    def normalized_host; @normalizer.call(host) end

    def http_get?; verb == 'GET' end
    def verb; @env['REQUEST_METHOD'] end

    def scheme; @env['rack.url_scheme'] end
    def host; @env['HTTP_HOST'] || @env['SERVER_NAME'] end

    def path; raw_path == '/' ? '' : raw_path end
    def query; raw_query == '' ? '' : "?#{raw_query}" end

    def raw_path; @env['PATH_INFO'] end
    def raw_query; @env['QUERY_STRING'] end
  end
end
