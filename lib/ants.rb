
require 'json'
require 'em-http'
require 'pp'

class Ants

  def self.run options
    if options[:file] 
      json = JSON.parse(File.read(options[:file]))
    end
    hosts = json['hosts'] 
    if options[:sample]
      # only first 5 not tested yet
      hosts = hosts[0..4]
    end
    puts "Loading "+ARGV[0] if options[:verbose]
    load_script(ARGV[0])
    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      hosts.each_with_index do |h,idx|
        
        url = "http://"+h.flatten[1]["host"] #.value["host"]
        puts "Before on_url(): "+url if options[:verbose]
        url = @sc.call_on_url(url)
        puts "After on_url(): "+url if options[:verbose]
        # need one hook to tamper url
        http = EventMachine::HttpRequest.new(url, :connect_timeout => 1)
        req = http.get
        multi.add idx, req
      end 
      multi.callback do 
        multi.responses[:callback].each do |response|
          @sc.call_on_response(response[1].response,response[1].response_header, response[1].req.uri.to_s)
        end
 

        #multi.responses[:errback].each do |response|
        #  @sc.call_on_response(response[1].response)
        #end
        #p multi.responses# [:callback]
        EventMachine.stop
      end
    }

  end

  def self.load_script(script)
    @sc = Script.new
    @sc.instance_eval(File.read(script))
  end

end

class Script
  def on_url(&block)
    Script.send(:define_method, "call_on_url") do |url|
      yield(url) if block_given?
    end 
  end
  def on_response(&block)
    Script.send(:define_method, "call_on_response") do |response, headers, url|
      yield(response, headers, url) if block_given?
    end 
  end


end
