#puts "Test dnscrypt-proxy configuration server connection"
def get_ip_list(fname)
ta=[]

 File.open(fname) do |file|
  file.each_line do |line|
    if line =~ /href=/
        code = line.scan(/(http[s]*:\/\/.*)\"\>(.*)\/a/)
        #p code.length
        #p code[0].length
        len = code[0][1].length

        #puts code[1].length
        #code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)[0] if code == nil
        ta.push([code[0][0],code[0][1][0..len-2]]) if code !=nil

    end #line

    #break
  end
end

 return ta
end




 def print_help
    puts "Test dnscrypt-proxy configuration server connection"
    puts "default file:/usr/local/Cellar/dnscrypt-proxy/1.6.0/share/dnscrypt-proxy/dnscrypt-resolvers.csv "
    puts "-d [filename] use dig  to test server connection"   
    puts "-p [filename] use ping to test server connection"    
    puts "-h            This help"    
  end

def to_len_s(s,width=16)
  len = s.length
  bs = s.bytesize
  if bs!=len
    len = 0
    s.chars.each do |c|
      if c.size == c.bytesize
        len+=1
      else
        len +=2
      end
    end
  end
  #p s
  #p len
  return s+' '*(width-len)
end
#main program start here...
fname = "/Users/mike/hexo/themes/pacman/layout/_widget/links.ejs"
fname = "/Users/mike/hexo/themes/concise/layout/_widget/links.ejs"

if ARGV.length != 0

    ARGV.each do |ele|  

           if  ele == '-h'          
            print_help
            exit 
           end 

           
           if ele == '-t'
            name = ARGV[ARGV.index(ele)+1]
            fname = name if name != nil 

            ta = get_ip_list(fname)
            ta.each {|h| puts "#{to_len_s(h[1])}: #{h[0]}"}
           end

            if ele == '-m'
            name = ARGV[ARGV.index(ele)+1]
            fname = name if name != nil 

            ta = get_ip_list(fname)
            ta.each {|h| puts "[#{h[1]}](#{h[0]})"}
           end

             if ele == '-n'
            name = ARGV[ARGV.index(ele)+1]
            fname = name if name != nil 

            ta = get_ip_list(fname)
            ta.each {|h| puts "#{h[1]}: #{h[0]}j "}
           end

           
     end #argv each
else
  print_help
end 


