foo = "a"
case foo
  when "a"
    puts "foo is a"
  when "b"
    puts "foo is b"
end

case foo
  when String
    puts "foo is string"
end