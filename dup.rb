class Dup
   def initialize
      @arr=[]
   end

   def add(size,name,full_name)
     return  if size < 50000 

     exist_r = @arr.index {|h| (h[:size]==size) and (h[:name] == name) }



     if nil == exist_r 
        ##h = 
        if full_name.index("usbbackup") != nil
          @arr.push({:size=>size,:name=>name,:full_name=>full_name})
        end
     else
        #p exist_r
        p "#{full_name} #{size}"
        p "#{@arr[exist_r][:full_name]} #{size}"
        #p "Found same file #{size},#{name}, #{full_name}"
     end
   end

end

class PhotoDup < Dup
    def add(size,name,full_name)

     return  if size < 50000 

      len=name.length
      return if len<5

      if ((name[-3..len-1]).upcase=="JPG") || ((name[-3..len-1]).upcase=="MP4")

      exist_r = @arr.index {|h| (h[:name] == name) }

     
         if nil == exist_r 

        if full_name.index("usbbackup") != nil
             @arr.push({:size=>size,:name=>name,:full_name=>full_name})
           end
            #@arr.push({:size=>size,:name=>name,:full_name=>full_name})
         else
            p "#{full_name} #{size}"
            p "#{@arr[exist_r][:full_name]} #{@arr[exist_r][:size]}"
         end

     end

    end
end

#$arr = Dup.new
$arr = PhotoDup.new

def to_str(size)

    return "#{size}" if size < 1024
    return "#{((size/1024.0)*100).to_i/100.0}K" if size < 1024*1024
    return "#{((size/1024.0/1024)*100).to_i/100.0}M" if size < 1024*1024*1024
    return "#{((size/1024.0/1024/1024)*100).to_i/100.0}G" 

    len = s.length
    s+' '*(10-len)
end

def walk(dir1,level=0,print_level=3)
    ta=[]
    totalsize = 0

    Dir.glob("#{dir1}\/.*").each do |afile|
        #p afile
        if (afile!="#{dir1}/.") and (afile!="#{dir1}/..")
          ta.push(afile)
        end
    end

    Dir.glob("#{dir1}\/*").each do |afile|
        ta.push(afile)      
    end

    ta.each do |item|
        #p item
        #walk(item) 
        if FileTest.directory?(item) 
            #p item
            totalsize += walk(item,level+1,print_level)
        else
          size = FileTest.size(item)
          totalsize += size
          #len = item.length
          #p item[2..len-1]
          #p File.basename(item)
          $arr.add(size,File.basename(item),item)
        end
    end

    s = to_str(totalsize)
    len = s.length
    s += ' '*(8-len)

   puts "#{s} | #{dir1}" if level<print_level
   return totalsize
end

#$arr = Dup.new

#travel directory and count all file size .
walk("/Users/mike/usbbackup",0,1)
walk(ARGV[0],0,ARGV[1].to_i) if FileTest.directory?(ARGV[0]) 

