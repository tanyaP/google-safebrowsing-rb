# download google safebrowsing hash list every 25 minutes. use tokyo hash as storage.
# http://code.google.com/apis/safebrowsing/developers_guide.html

# sudo ttserver -port 1800 safebrowsing.tch#opts=lb

require 'rubygems'
require 'rufus/tokyo/tyrant'
require File.join(File.expand_path(File.dirname(__FILE__)), '../../http_base.rb')

class SafeBrowsingDaemon
  def initialize
    # sudo ttserver -port 1800 safebrowsing.tch#opts=lb
    @safebrowsing = Rufus::Tokyo::Tyrant.new('localhost', 1800)
    @http = BuzzHTTP.new
    # 10 minutos de timeout (download first list)
    @http.timeout(600)
    @api = "http://sb.google.com/safebrowsing/update?client=api&apikey=ABQIAAAAHjv9EXnqegadKyb5ju7WRBS72CyDJtrd4tEcp6bTVv-RfT7phA"
  end
  
  def run
    ["goog-malware-hash", "goog-black-hash"].each do |list|
      @safebrowsing[list]
      unless @safebrowsing[list].nil?
        result = @http.open_url("#{@api}&version=#{list}:1:#{@safebrowsing[list]}")[:body]
      else
        result = @http.open_url("#{@api}&version=#{list}:1:-1")[:body]
      end
      
      unless result.empty?
        version = result.match(/[^\.]*\.([^ ]*)( update)?\]/)
        @safebrowsing[list] = "#{version[1]}"

        # save hash
        (result << " ").split(/\]\n/)[1].split(/\t?\n\n?/).each do |hash|
          if hash[0..0] == "+"
            p "add #{hash[1..-1]}"
            @safebrowsing[hash[1..-1]] = ""
          elsif hash[0..0] == "-"
            p "remove #{hash[1..-1]}"
            @safebrowsing[hash[1..-1]] = nil
          end
        end        
      end
    end
    
    # dorme 25 minutos
    1500
  end
end

safelist = SafeBrowsingDaemon.new
loop do
  wait = safelist.run
  p "...waiting: #{wait}"
  sleep wait if wait and wait > 0 
end