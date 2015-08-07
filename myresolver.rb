require 'rubydns'
require 'time'
require_relative 'domestic_addr'


class MyResolver < RubyDNS::Resolver

    def initialize(servers, options = {})
    	    @domestic_addr = Domestic_address.new('chnroute.txt','domestic_name.conf')
    	   # @domestic_addr.load_domestic_file('chnroute.txt')

    	    @cache=[]
    	    load_cache('oversea.conf')
    	    @oversea_resolve = File.open('oversea.conf','a')

			super
    end

  
    def close_file
    	@oversea_resolve.close
    end
	
	def dispatch_request(message)

		    name = get_request_domain_name(message)
		    if (h = @cache.find {|h| (h[:name] == name) and h[:state_valid]}) != nil
		    	t = Time.now
		    	if (t-h[:time] < h[:ttl][0])  # update cache every 12 hour
		    	  @logger.debug "Found in cache #{name} #{h[:ip]} in cache keep in #{t-h[:time]} seconds" if @logger 
                  return h[:response]
                else
                  #@cache.delete_if {|h| h[:name] == name}
                  h[:state_valid] = false
                end
		    end

		 	domestic_resp, domestic_addr = get_domestic_reponse(message)

            if (domestic_addr.length!=0) and force_in_domestic?(name)
              @logger.debug "Force domestic resolver [#{name}  #{arr_to_s(get_iplist_from_response(domestic_addr))}] " if @logger
		      return domestic_resp  
		    end
		 	
		 	#@logger.debug "domestic_addr =  #{domestic_addr} " if @logger 
             ip_list = get_iplist_from_response(domestic_addr)
		 	if (ip_list.length!=0) and  match_domestic?(ip_list[0].to_s)
		 		
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
			 	    if ((h = @cache.find {|h| (h[:name] == name) }) == nil)  #not found
		 		        
                        h=Hash.new
				 		h[:name] = get_request_domain_name(message)
				 		h[:ip]   = get_iplist_from_response(oversea_addr)
				 		h[:ttl]  = get_ttl_from_response(oversea_addr)
				 		h[:response] = oversea_resp
				 		h[:time] = Time.now
				 		h[:state_valid] = true
				 		@cache.push(h) 
				 		#append_record(h[:name],h[:ip])
			 	    else #found,  h[:state_valid] must be false
			 	    	h[:name] = get_request_domain_name(message)
				 		h[:ip]   = get_iplist_from_response(oversea_addr)
				 		h[:ttl]  = get_ttl_from_response(oversea_addr)
				 		h[:response] = oversea_resp
				 		h[:time] = Time.now
				 		h[:state_valid] = true
				 		@logger.debug "Updating [#{h[:name]} #{arr_to_s(h[:ip])} #{arr_to_s(h[:ttl])}] " if @logger
				 		#append_record(h[:name],h[:ip])
			 	    end
			 	    append_record(h[:name],arr_to_s(h[:ip]))

		 	    end

		 	    


                return oversea_resp 
            end
            
		end #end of dispatch

        private

		def get_type_a_address(name,response,oversea_flag=false)
			result = []

            #return result if response==nil
			#return result if response.answer==nil
			#@logger.debug "get_address #{response.inspect} " if @logger
            
            response.answer.each do |res|
	            res.each do |x|
	              #@logger.debug "get_address #{x.inspect} " if @logger
	              if x.class == Resolv::DNS::Resource::IN::A #only process A type record
	              	result.push([x.address.to_s,x.ttl.to_i]) if x!=nil
	              end
	            end
            end

            # result.each do |addr| 
            # 	@logger.debug "oversea  get_address  #{addr} " if @logger and oversea_flag
            # 	@logger.debug "domestic get_address  #{addr} " if @logger and not oversea_flag
            # end

            #ip_list = result.inject(""){|r,v| r<<(v+' ')}
            # ip_list =""
            # result.each do |addr|
            # 	ip_list << ("#{addr[0]}:#{addr[1].to_i}")
            # end 
            ip_list = arr_to_s(get_iplist_from_response(result))
            ttl_list = arr_to_s(get_ttl_from_response(result))

            #if ip_list!=""
              @logger.debug "oversea  : address=/#{name}/#{ip_list}/#{ttl_list}" if @logger and oversea_flag
              @logger.debug "domestic : address=/#{name}/#{ip_list}/#{ttl_list} " if @logger and not oversea_flag
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
						addr = get_type_a_address(get_request_domain_name(message),response,oversea_flag)
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
			return query_dns(message, [[:udp, "192.168.1.1", 53],[:udp, "223.5.5.5", 53],[:udp, "14.18.142.2", 53]])
		end 
		def get_oversea_reponse(message)
			return query_dns(message, [[:udp, "127.0.0.1", 5533]],true)
		end 

		def get_request_domain_name(message)
			name = message.question[0][0].to_s
		   return name[0..name.length-2]
	    end

	    def append_record(name,ip)
    	@logger.debug "Writing oversea: #{name} #{ip}" if @logger 
    	@oversea_resolve.puts("address=/#{name}/#{ip}")
	    end

	    def match_domestic?(ip)
	    	return @domestic_addr.belong_to?(ip)
	    end

	    def force_in_domestic?(ip)
	    	return @domestic_addr.is_force_domain?(ip)
	    end

	    def get_iplist_from_response(result)
            return result.collect{|addr| addr[0]}
		end

		def get_ttl_from_response(result)
            return result.collect{|addr| addr[1]}
		end

		def arr_to_s(arr)
			arr.inject(""){|r,v| r<<"#{v.to_s} "}.strip
		end
        
        def load_cache(fname)
		   File.open(fname) do |file|
	        file.each_line do |line|
	          temp,name,iplist = line.split('/')
	          if (h = @cache.find {|h| h[:name] == name}) == nil
	          	 h=Hash.new
		 	     h[:name] = name
		 		 h[:ip]   = iplist.split(' ')
		 		 h[:ttl]  =  h[:ip].collect {|x| 60} # 11 minitues default
		 		 h[:time] = Time.now
		 		 h[:state_valid] = true
		 		 h[:response] = make_response(h)
		 		 @cache.push(h) 
	          else #this domain exists
	          	update_flag = false
	          	iplist.split(' ').each do |ip|
	          	  if (nr=h[:ip].find{|x| x==ip})==nil
	          	  	h[:ip].push(ip)
	          	  	update_flag = true
	          	  end
	          	end
	            h[:response] = make_response(h) if update_flag
	          end

            end
          end
	end #end of load_cache

	def  to_hex(s)
		#p s
	    return (s.split('.').inject('') {|res,var| res << ("%02x" % var.to_i )}).to_i(16)
	    #p s.split('.')
	end

	def make_response(h)
		response = Resolv::DNS::Message.new
		response.add_question(h[:name],Resolv::DNS::Resource::IN::A)
        h[:ip].each do |ip|
        	# ip.split('.').collect{|x| x.to_i}.pack ('C4')
		  ip=Resolv::DNS::Resource::IN::A.new(ip)
		  def ip.ttl= (ttl)
		  	@ttl = ttl
		  end
		  ip.ttl = h[:ttl][0]
		  response.add_answer(h[:name],h[:ttl][0],ip)
	    end
		return response
	end
		



end