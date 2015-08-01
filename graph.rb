src_box = []
File.open('gem_relationship.gv', 'w') do |t|
  t.puts "digraph G {"
  File.open("Gemfile.lock").each do |n|
    # 通过缩进来判断指向关系.
    n =~ /^( {2,})([a-zA-Z0-9_-]+)/
    if $1 and $1.length == 4
      @src = $2
      src_box << @src
    elsif $1 and $1.length == 6
      @target = $2
      puts @src
      t.puts "  \"#{@src}\" -> \"#{@target}\""
    else
    end
  end
  t.puts "}"
end
