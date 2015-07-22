def print_zero_filter()
  # ta=[]

  # File.open(fname) do |file|

     
  #     file.each_line do |line|
     while (true)
     line = gets
       	if line =~ /DROP/
	      		#p line
	         #code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\./)
	         code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/24/)[0]
           code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)[0] if code==nil

           packets = (line.scan(/[0-9]+/)[0]).to_i 
           
           if packets == 0
             puts "iptables -D INPUT -s #{code} -j DROP" 
           end
           
	        

              
        end #line
        
        #break
      end
  #end

 
  #return ta
end

#p ARGV[0]
#
#


print_zero_filter