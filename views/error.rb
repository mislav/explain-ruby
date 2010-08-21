module Sinatra::Application::Views
  class Error < Mustache
    
    def title
      "Oh Noes!"
    end
    
    def error_message
      @message
    end
    
  end
end
