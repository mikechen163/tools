require 'rubydns'
require 'time'
require_relative 'domestic_addr'


class MyResolver < RubyDNS::Resolver

    def initialize(servers, options = {})
    	    @domestic_addr = Domestic_address.new('chnroute.txt','domestic_name.conf')
    	   # @domestic_addr.load_domestic_file('chnroute.txt')

    	    @cache=[]

			super
    end

    def match_domestic?(ip)
    	return @domestic_addr.belong_to?(ip)
    end

    def force_in_domestic?(ip)
    	return @domestic_addr.is_force_domain?(ip)
    end
	
	def dispatch_request(message)

		    name = get_request_domain_name(message)
		    if (h = @cache.find {|h| (h[:name] == name) and h[:state_valid]}) != nil
		    	t = Time.now
		    	if (t-h[:time] < 60*60*12)  # update cache every 12 hour
		    	  @logger.debug "find #{name} #{h[:ip]} in cache keep in #{t-h[:time]} seconds" if @logger 
                  return h[:response]
                else
                  #@cache.delete_if {|h| h[:name] == name}
                  h[:state_valid] = false
                end
		    end

		 	domestic_resp, domestic_addr = get_domestic_reponse(message)

            if (domestic_addr.length!=0) and force_in_domestic?(name)
              @logger.debug "force in domesic [#{name}  #{result_to_s(domestic_addr)}] " if @logger
		      return domestic_resp  
		    end
		 	
		 	#@logger.debug "domestic_addr =  #{domestic_addr} " if @logger 

		 	if (domestic_addr.length!=0) and  match_domestic?(domestic_addr[0].to_s)
		 		
		 		#do not buffer domestic ip
		 		# if ((h = @cache.find {|h| (h[:name] == name) and (not h[:state_valid])}) == nil)
		 		#   h=Hash.new
		 	 #    end

		 		# h[:name] = get_request_domain_name(message)
		 		# h[:ip] =domestic_addr[0].to_s
		 		# h[:response] = domestic_resp
		 		# h[:time] = Time.now
		 		# h[:state_valid] = true
		 		# @cache.push(h) 
		 		return domestic_resp 

		 	else
              	oversea_resp,oversea_addr  = get_oversea_reponse(message)
                
                if (oversea_addr.length!=0) 
			 	    #h=Hash.new
			 	    if ((h = @cache.find {|h| (h[:name] == name) and (not h[:state_valid])}) == nil)
		 		       h=Hash.new
		 	        end
			 		h[:name] = get_request_domain_name(message)
			 		h[:ip] =oversea_addr[0].to_s
			 		h[:response] = oversea_resp
			 		h[:time] = Time.now
			 		h[:state_valid] = true
			 		@cache.push(h) 
		 	    end

		 	    


                return oversea_resp 
            end
            
		end #end of dispatch

		def result_to_s(result)
			ip_list =""
            result.each do |addr|
            	ip_list << (addr.to_s + ' ')
            end 

            return ip_list

		end

		def get_address(name,response,oversea_flag=false)
			result = []

            #return result if response==nil
			#return result if response.answer==nil
            
            response.answer.each do |res|
	            res.each do |x|
	              #@logger.debug "get_address #{x.inspect} " if @logger
	              if x.class == Resolv::DNS::Resource::IN::A
	              	result.push(x.address) if x!=nil
	              end
	            end
            end

            # result.each do |addr| 
            # 	@logger.debug "oversea  get_address  #{addr} " if @logger and oversea_flag
            # 	@logger.debug "domestic get_address  #{addr} " if @logger and not oversea_flag
            # end

            #ip_list = result.inject(""){|r,v| r<<(v+' ')}
            ip_list =""
            result.each do |addr|
            	ip_list << (addr.to_s + ' ')
            end 

            #if ip_list!=""
              @logger.debug "oversea  : address=/#{name}/#{ip_list} " if @logger and oversea_flag
              @logger.debug "domestic : address=/#{name}/#{ip_list} " if @logger and not oversea_flag
            #end

			return result
		end

		def query_dns(message,server_list,oversea_flag=false)
			request = Request.new(message,server_list)
			request.each do |server|
				#@logger.debug "[#{message.id}] Sending request #{message.question} to server #{server.instance_variables}" if @logger
				@logger.debug "[#{message.id}] Sending request [#{get_request_domain_name(message)}] to server #{server.inspect}" if @logger
				
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
						addr = get_address(get_request_domain_name(message),response,oversea_flag)
						return response , addr
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

			return nil,[]
		end #end of query_dns

		def get_domestic_reponse(message)
			return query_dns(message, [[:udp, "223.5.5.5", 53],[:udp, "14.18.142.2", 53]])
		end 
		def get_oversea_reponse(message)
			return query_dns(message, [[:udp, "127.0.0.1", 5533]],true)
		end 

		def get_request_domain_name(message)
			name = message.question[0][0].to_s
		   return name[0..name.length-2]
	    end

end