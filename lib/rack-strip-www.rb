require 'uri'

module Rack
  class StripWWW
    def initialize(app)
      @app = app
    end
  
    def call(env)
      if env['REQUEST_METHOD'] != 'GET'
        @app.call(env)
      else
        host = env['HTTP_HOST'] || env['SERVER_NAME']
        stripped_host = strip_www(host)

        if stripped_host == host
          @app.call(env)
        else
          scheme = env['rack.url_scheme']
          path = env['PATH_INFO']
          path = '' if path == '/'
          query = env['QUERY_STRING']
          query = '?' + query unless query == ''
          new_url = "#{scheme}://#{stripped_host}#{path}#{query}"
          [301, { 'Location' => new_url }, new_url]
        end
      end
    end
  
    def strip_www(host)
      case host
      when /^www\.(([^.]+\.){1,2}[a-z]+)$/
        $1
      else
        host
      end
    end
  end
end
