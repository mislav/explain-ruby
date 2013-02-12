module Sinatra::Application::Views
  class Layout < Mustache
    include TrackingCode
    
    def highlight_style
      ::Sinatra::Application.rocco[:uv_style]
    end
  
    def title
      "Explain Ruby"
    end
  
  end
end
