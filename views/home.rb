require 'views/layout'

module Sinatra::Application::Views
  class Home < Layout
  
    def bookmarklet
      %(javascript:window.location="http://#{@request.host}/url/"+window.location)
    end
    
  end
end
