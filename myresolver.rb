require 'rubydns'
require 'time'
require_relative 'domestic_addr'


class MyResolver < RubyDNS::Resolver

    def initialize(servers, options = {})
    	    @domestic_addr = Domestic_address.new
    	    @domestic_addr.load_domestic_file('chnroute.txt')

    	    @cache=[]

			super
    end

    def match_domestic?(ip)
    	return @domestic_addr.belong_to?(ip)
    end
	
	def dispatch_request(message)

		    name = get_request_domain_name(message)
		    if (h = @cache.find {|h| h[:name] == name}) != nil
		    	t = Time.now
		    	if (t-h[:time] < 60*60*12)  # update cache every 12 hour
		    	  @logger.debug "find #{name} #{h[:ip]} in cache keep in #{t-h[:time]} seconds" if @logger 
                  return h[:response]
                else
                  @cache.delete_if {|h| h[:name] == name}
                end
		    end

		 	domestic_resp = get_domestic_reponse(message)
		 	domestic_addr = get_address(domestic_resp) 

		 	#@logger.debug "domestic_addr =  #{domestic_addr} " if @logger 

		 	if match_domestic?(domestic_addr[0].to_s)
		 		h=Hash.new
		 		h[:name] = get_request_domain_name(message)
		 		h[:ip] =domestic_addr[0].to_s
		 		h[:response] = domestic_resp
		 		h[:time] = Time.now
		 		@cache.push(h) 
		 		return domestic_resp 
		 	else
              	oversea_resp  = get_oversea_reponse(message)
		 	    oversea_addr  = get_address(oversea_resp,true) 

		 	    h=Hash.new
		 		h[:name] = get_request_domain_name(message)
		 		h[:ip] =oversea_addr[0].to_s
		 		h[:response] = oversea_resp
		 		h[:time] = Time.now
		 		@cache.push(h) 
                return oversea_resp 
            end
            
		end #end of dispatch

		def get_address(response,oversea_flag=false)
			result = []
            
            response.answer.each do |res|
	            res.each do |x|
	              #@logger.debug "get_address #{x.inspect} " if @logger
	              if x.class == Resolv::DNS::Resource::IN::A
	              	result.push(x.address)
	              end
	            end
            end

            result.each do |addr| 
            	@logger.debug "oversea  get_address  #{addr} " if @logger and oversea_flag
            	@logger.debug "domestic get_address  #{addr} " if @logger and not oversea_flag
            end

			return result
		end

		def query_dns(message,server_list)
			request = Request.new(message,server_list)
			request.each do |server|
				#@logger.debug "[#{message.id}] Sending request #{message.question} to server #{server.instance_variables}" if @logger
				@logger.debug "[#{message.id}] Sending request #{get_request_domain_name(message)} to server #{server.inspect}" if @logger
				
				begin
					response = nil
					
					# This may be causing a problem, perhaps try:
					# 	after(timeout) { socket.close }
					# https://github.com/celluloid/celluloid-io/issues/121
					timeout(request_timeout) do
						#@logger.debug "[#{message.id}] My Try #{server[0]}:#{server[1]}..." if @logger
						response = try_server(request, server)
					end
					
					if valid_response(message, response)
						return response
					end
				rescue Task::TimeoutError
					@logger.debug "[#{message.id}] Request timed out!" if @logger
				rescue InvalidResponseError
					@logger.warn "[#{message.id}] Invalid response from network: #{$!}!" if @logger
				rescue DecodeError
					@logger.warn "[#{message.id}] Error while decoding data from network: #{$!}!" if @logger
				rescue IOError
					@logger.warn "[#{message.id}] Error while reading from network: #{$!}!" if @logger
				end
			end

			return nil
		end #end of query_dns

		def get_domestic_reponse(message)
			return query_dns(message, [[:udp, "223.5.5.5", 53],[:udp, "14.18.142.2", 53]])
		end 
		def get_oversea_reponse(message)
			return query_dns(message, [[:udp, "127.0.0.1", 5533]])
		end 

		def get_request_domain_name(message)
		   return message.question[0][0].to_s
	    end

end