module Rack
  class StripWWW
    def self.strip_www(host)
      case host
      when /^www\.(([^.]+\.){1,2}[a-z]+)$/
        $1
      else
        host
      end
    end
  end
end
