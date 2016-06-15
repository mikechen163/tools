p_line = ""
IO.foreach("pics2.txt") do |line|  
  if line =~ /usbback/  
    if p_line =~ /photoslibrary/
      puts p_line
      puts line
    end
  end
  p_line = line.dup
end  