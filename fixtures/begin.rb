def explosive
  begin
    raise "OH SHIT"
  rescue
    puts "Naw it's ok."
  ensure
    puts "Seriously. Chill."
  end
end