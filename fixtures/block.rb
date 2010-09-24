def foo
  puts "moo"
end

foo do |blah, blah2|
  hey
  hey
end

foo { |moo, blah| hey }