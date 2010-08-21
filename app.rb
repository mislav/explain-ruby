require 'sinatra'
require 'sass'
require 'pp'
require 'code'

require 'mustache/sinatra'
set :mustache, { :templates => './templates', :views => './views' }

require 'rocco'
Rocco::Layout.template_path = Sinatra::Application.mustache[:templates]
Rocco::Layout.template_name = 'rocco'

helpers do
  def email_link(email)
    "<a href='mailto:#{email}'>#{email}</a>"
  end
  
  def link_to(object)
    case object
    when Project
      "<a href='#{project_path(object)}'>#{object.name}</a>"
    when Company
      "<a href='#{company_path(object)}'>#{object.name}</a>"
    else
      raise ArgumentError
    end
  end
  
  def image_tag(file, attributes = {})
    attributes = attributes.merge(:src => "/images/#{file}")
    attributes[:alt] ||= ''
    "<img#{html_attributes(attributes)}>"
  end
  
  def html_attributes(hash)
    hash.map { |key, value|
      case value
      when NilClass, FalseClass
        ''
      when TrueClass
        " #{key}"
      else
        " #{key}='#{value}'"
      end
    }.join('')
  end
  
  def rocco(filename = default_title, options = {}, &block)
    options = {:comment_chars => '>'}.update(options)
    Rocco.new(filename, [], options, &block).to_html
  rescue Racc::ParseError
    status 500
    @message = "There was a parse error when trying to process Ruby code"
    mustache :error
  end
  
  def default_title
    "Explain Ruby"
  end
end

get '/' do
  mustache :home
end

post '/' do
  if not params[:url].empty?
    code = ExplainRuby::Code.from_url params[:url]
    rocco { code.to_s }
  elsif not params[:code].empty?
    code = ExplainRuby::Code.new params[:code]
    rocco { code.to_s } 
  else
    status "400 Not Chunky"
    @message = "Please paste some code or enter a URL"
    mustache :error
  end
end

get '/f/:name' do
  # content_type 'text/plain'
  file = File.open("./fixtures/#{params[:name]}.rb")
  rocco(file.path) { insert_explanations ruby2ruby(file) }
end

get '/f/:name/sexp' do
  content_type 'text/plain'
  file = File.open("./fixtures/#{params[:name]}.rb")
  ruby2sexp(file).pretty_inspect
end

get '/chunky.css' do
  content_type 'text/css'
  sass :style
end

get '/docco.css' do
  content_type 'text/css'
  sass :docco
end
