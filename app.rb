require 'sinatra'
require 'sass'
require 'pp'
require 'code'

require 'mustache/sinatra'
set :mustache, { :templates => './templates', :views => './views' }

require 'rocco_ext'

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
    options = settings.rocco.merge(options)
    Rocco.new(filename, [], options, &block).to_html
  rescue Racc::ParseError
    status 500
    @message = "There was a parse error when trying to process Ruby code"
    mustache :error
  end
  
  def default_title
    "Explain Ruby"
  end
  
  def sass_with_caching(name)
    time = ::File.mtime ::File.join(settings.views, "#{name}.sass")
    expires 500, :public, :must_revalidate if settings.environment == :production
    last_modified time
    content_type 'text/css'
    sass name
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
  code = ExplainRuby::Code.from_test_fixture(params[:name])
  rocco(code.url) { code.to_s }
end

get '/f/:name/sexp' do
  content_type 'text/plain'
  code = ExplainRuby::Code.from_test_fixture(params[:name])
  code.pretty_inspect
end

get '/chunky.css' do
  sass_with_caching :style
end

get '/docco.css' do
  sass_with_caching :docco
end
