#puts "Test dnscrypt-proxy configuration server connection"
def get_ip_list(fname)
ta=[]

 File.open(fname) do |file|
  file.each_line do |line|
    if line =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/
        code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/)[0]
        #p code
        code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)[0] if code == nil
        ta.push(code) if code !=nil

    end #line

    #break
  end
end

 return ta
end

def dig_test(ip)
  port_start = ip.index(':')
  len=ip.length

  addr = ip
  port = 53
  if port_start!=nil
   port = ip[port_start+1..len-1].to_i 
   addr = ip[0..port_start-1]
  end

  result = `dig @#{addr} -p #{port} www.bbc.com`
  rsp = result.split(';').grep /Query/
  #p rsp.inspect

   
  "[#{addr}:#{port.to_s} #{rsp[0]}]"
end

def ping_test(ip)
  port_start = ip.index(':')
  len=ip.length

  addr = ip
  port = 53
  if port_start!=nil
   port = ip[port_start+1..len-1].to_i 
   addr = ip[0..port_start-1]
  end

  result = `ping -c 10 #{addr}` 
  #rsp = result.split('\n').grep /loss/
  rsp=""
  #p result.class
  pos1 = result.index('received')
  pos2 = result.index('round')
  return "[#{addr}=>timeout]" if (pos1==nil) or (pos2==nil)
  len = result.length
  result[pos2-1] = ','
  result[len-1] = '.'

  rsp += result[pos1+10..len-1]
   
  "[#{addr}=>#{rsp}]"
end


 def print_help
    puts "Test dnscrypt-proxy configuration server connection"
    puts "default file:/usr/local/Cellar/dnscrypt-proxy/1.6.0/share/dnscrypt-proxy/dnscrypt-resolvers.csv "
    puts "-d [filename] use dig  to test server connection"   
    puts "-p [filename] use ping to test server connection"    
    puts "-h            This help"    
  end

#main program start here...
fname = "/usr/local/Cellar/dnscrypt-proxy/1.6.0/share/dnscrypt-proxy/dnscrypt-resolvers.csv"

if ARGV.length != 0

    ARGV.each do |ele|  

           if  ele == '-h'          
            print_help
            exit 
           end 

           
           if ele == '-d'
            name = ARGV[ARGV.index(ele)+1]
            fname = name if name != nil 

            ta = get_ip_list(fname)
            ta.each {|h| p dig_test(h)}
           end

            if ele == '-p'
            name = ARGV[ARGV.index(ele)+1]
            fname = name if name != nil 

            ta = get_ip_list(fname)
            ta.each {|h| p ping_test(h)}
           end
     end #argv each
else
  print_help
end 


