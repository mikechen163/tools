#get ip list from ssh_log file.
def get_ip_list(fname)
ta=[]

 File.open(fname) do |file|
  file.each_line do |line|
    if line =~ /from\s+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/
        code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)[0]
        time_stamp = line.scan(/[A-Za-z]+\s+\w\s+[0-9]+\:[0-9]+\:[0-9]+/)[0]
        time_stamp = "" if time_stamp == nil
       
         next if code.index("xxx.xxx")!=nil # 这里的xxx.xxx就是自己的IP子网前缀。把自己的IP去掉，防止自己也登录不了！！！

         h =  ta.find {|h| h[:ip] == code}
         if h!=nil
            h[:counter] +=1
           h[:time_stamp] = time_stamp
         else
           h=Hash.new
           h[:ip] = code
           h[:counter] = 1
          h[:time_stamp] = time_stamp
           ta.push(h)
         end


    end #line

    #break
  end
end
 ta.sort_by! {|h| h[:time_stamp]}
 ta.reverse!
 return ta
end

#merge ip into class 3 subnet.
def merge_ip_list(ta)
      nta = ta.map do |h| 
        na = (h[:ip].scan /[0-9]+\./)
        na[0]+na[1]+na[2]+'0/24'
      end

      nta.uniq!

      ra=nta.map do |ip|
        ind = ip.index('0/24')
        s1 = ip[0..ind-1]
        rep_times =  ta.count{|h| h[:ip].index(s1)!=nil}
        final = (rep_times>1) ? ip : (ta.find{|h| h[:ip].index(s1)!=nil})[:ip]
        i_counter =  (ta.select{|h| h[:ip].index(s1)!=nil}).inject(0) { |mem, var| mem + var[:counter] }
        {:ip=>final,:counter=>i_counter}
      end
 
    return ra
end

 def print_help
    puts "All rights reserved.  send email to mikechen163@hotmail.com if you have any suggestions ."
    puts "This Tool is used to make analysis for sshd Failed log file. the follow command generate ssh_log.txt"
    puts "#tail -n 1000 /var/log/secure | grep Failed > ssh_log.txt"
    puts "#ruby analysis_ssh_log.rb -v -m ssh_log.txt"
    puts
    puts "-f logfile            show ssh failed log ip,counter, last access time_stamp"
    puts "-v                    generate delete command for iptables should use with -g or -m "  
    puts "-g logfile [counter]  generate insert command for iptables for each ip"  
    puts "-m logfile [counter]  generate insert command for iptables for each subnet"  
    puts "-h                    This help"    
  end

#main program start here...
delete_flag = false
if ARGV.length != 0

ARGV.each do |ele|  

 if  ele == '-h'          
  print_help
  exit 
 end 

 #显示ssh攻击的情况，按照时间倒序排列
 if ele == '-f'
  fname = ARGV[ARGV.index(ele)+1]

  ta = get_ip_list(fname)
  ta.each {|h| p h}
 end

 if ele == '-v' 
   delete_flag = true
 end

  #生成针对ip的限制表项，后面的参数是counter数目
 if (ele == '-g' ) or (ele == '-m' )
    fname = ARGV[ARGV.index(ele)+1]
    counter  = ARGV[ARGV.index(ele)+2].to_i
    counter = 100 if counter == 0

    ta = get_ip_list(fname) if (ele == '-g' )
    ta = merge_ip_list(get_ip_list(fname)) if (ele == '-m' )

    if not delete_flag 
      ta.each {|h| puts "iptables -I INPUT -s #{h[:ip]} -j DROP" if (h[:counter] >= counter)}
    else
      ta.each {|h| puts "iptables -D INPUT -s #{h[:ip]} -j DROP" if (h[:counter] >= counter)}
    end
  end

 end
end 


def merge_ip_list(s)

  ta = s.split('|')

  nta = ta.map do |h| 
   na = (h.scan /[0-9]+\./) 
   na[0]+na[1]+na[2]+'0-'+ na[0]+na[1]+na[2]+'255'
  end 

  nta.uniq!
  nta.each {|x| p x}

end 
