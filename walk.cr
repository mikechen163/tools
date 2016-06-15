def to_str(size)

	return "#{size}" if size < 1024
	return "#{((size/1024.0)*100).to_i/100.0}K" if size < 1024*1024
	return "#{((size/1024.0/1024)*100).to_i/100.0}M" if size < 1024*1024*1024
	return "#{((size/1024.0/1024/1024)*100).to_i/100.0}G" 

	#len = s.length
	#return s+' '*(10-len)
end

def nsp(num)
    s=""
    i=0
    while i<num
      s+= ' ' 
      i+=1
    end

    return s
end

def walk(dir1,level=0,print_level=3)
	ta=[] of String
	totalsize = 0_u64

	Dir.glob("#{dir1}\/.*").each do |afile|
		#p afile
        next if afile =="#{dir1}/."
        next if afile =="#{dir1}/.."
		
		ta.push(afile)
		
	end

	Dir.glob("#{dir1}\/*").each do |afile|
		ta.push(afile)		
	end

	ta.each do |item|
		#p item
		#walk(item)	
        begin
            if File.directory?(item) 
            	#p item
                if File.symlink?(item)== false
    		      totalsize += walk(item,level+1,print_level)
                end
            else
             
                size =  File.size(item)
             
                totalsize += size
             
            end
        rescue
            #puts "Error : #{item}"
            return totalsize
        end
    end

    s = to_str(totalsize)
    len = s.size
	s += nsp(8-len)

   puts "#{s} | #{dir1}" if level<print_level
   return totalsize
end

#travel directory and count all file size .
if ARGV.size !=0
  level = 2 
  level =ARGV[1].to_i if ARGV.size >= 2
  walk(ARGV[0],0,level) if File.directory?(ARGV[0])
else
  walk(".",0,2) 
end

