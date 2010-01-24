# safebrowsing client
# lookups for hash key in tokyo

require 'rubygems'
require 'addressable/uri'
require 'rufus/tokyo/tyrant'
require 'digest/md5'

class SafeBrowsingClient
  attr_reader :safebrowsing
  def initialize
    # sudo ttserver -port 1800 safebrowsing.tch#opts=lb
    @safebrowsing = Rufus::Tokyo::Tyrant.new('localhost', 1800)
  end
  
  def md5(str)
    Digest::MD5.hexdigest(str)
  end
  
  def lookup(uri)
    uri = Addressable::URI.heuristic_parse(uri.downcase).to_str
    url_components = uri.match(Regexp.new('^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?'))
    
    lookup_list = []
    hostname = url_components[4]
    unless hostname.nil?
      hostname_comp = hostname.split('.')
      (hostname_comp.size - 1).times do |i|
        filtered_hostname_comp = hostname_comp[i..-1].join('.')
        lookup_list.push(md5("#{filtered_hostname_comp}/"))
        if url_components[5]
          path = url_components[5].split('/')
          (path.size + 1).times do |j|
            filtered_paths = path[0..j].join('/')
            unless filtered_paths.include?('.')
              lookup_list.push(md5("#{filtered_hostname_comp}/#{filtered_paths}"))
            end
          end
          lookup_list.push(md5("#{filtered_hostname_comp}#{url_components[5]}"))
          if url_components[6]
            lookup_list.push(md5("#{filtered_hostname_comp}#{url_components[5..7].join('')}"))
            if url_components[8]
              lookup_list.push(md5("#{filtered_hostname_comp}#{url_components[5..7].join('')}#{url_components[8]}"))
            end
          end
        end
      end
    end
    
    (@safebrowsing.lget(lookup_list).size > 0)
  end
end

# malware.testing.google.test/testing/malware/
# (dc5178cc1a0820bc434c83d2f089f105)

# auto test
# safebrowsing = SafeBrowsingClient.new
# p safebrowsing.lookup("http://malware.testing.google.test/testing/malware/")