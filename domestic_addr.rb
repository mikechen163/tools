class Domestic_address 

 def load_domestic_file(fname)
		@ta = []
        File.open(fname) do |file|
	        file.each_line do |line|
	          code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+/)[0]
	          #p code
	          t1 = code.index('/')
	          mask_len = code[t1+1..code.length-1].to_i
              mask = ('1'*mask_len+'0'*(32-mask_len)).to_i(2)
	          
	          @ta.push( [ (to_hex(code[0..t1-1]) & mask),mask,mask_len,code])
            end
         end

         # p @ta.length
         
         # @ta.each do |x|
         #   puts "#{(x[0].to_s(16))},#{to_ip(x[0])},#{x[1].to_s(16)},#{x[2]},#{x[3]}" 
         # end
	end #load_domectic_file

	def show_ele(x)
	  "#{(x[0].to_s(16))},#{to_ip(x[0])},#{x[1].to_s(16)},#{x[2]},#{x[3]}" 
	end

	# def ip_conver(str_ip)  
 #        ip_16=''  
	#     str_ip.split('.').each do |k|  
	#         k="%02x" % k  
	#         ip_16=ip_16+k.to_s  
	#     end  
 #        puts @ip_16.to_i(16)  
 #    end 
 #  
    def to_ip(hn)
    	s=hn.to_s(16)
    	if s.length == 8
    	  (s[0..1].to_i(16)).to_s+'.'+(s[2..3].to_i(16)).to_s+'.'+(s[4..5].to_i(16)).to_s+'.'+(s[6..7].to_i(16)).to_s
        else
       	  (s[0].to_i(16)).to_s+'.'+(s[1..2].to_i(16)).to_s+'.'+(s[3..4].to_i(16)).to_s+'.'+(s[5..6].to_i(16)).to_s 	
        end
    end

	def  to_hex(s)
		#p s
	    return (s.split('.').inject('') {|res,var| res << ("%02x" % var.to_i )}).to_i(16)
	    #p s.split('.')
	end

	def  belong_to?(ip)
        ip_hex = to_hex(ip) 
        @ta.each do |na|
        	res = na[0]
        	mask = na[1]
        	mat = ip_hex & mask
        	if (mat == res)
                # p show_ele(na)
                # p ip_hex.to_s(16)
                # p mat.to_s(16)
                # p to_ip(ip_hex)             
        		return true
        	end

        	#return true if (ip_hex & mask) == res 
        end

        return false
	end
end

# da=Domestic_address.new

# da.load_domestic_file('chnroute.txt')
# #p da.to_hex('192.168.3.21')
# #

#  p da.belong_to?('43.227.156.2').to_s
#  p da.belong_to?('223.255.240.2').to_s
