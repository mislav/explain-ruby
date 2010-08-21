require 'sinatra'
require 'ruby2ruby'
require 'ruby_parser'
require 'sass'
require 'pp'

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
  
  def rocco(filename, options = {}, &block)
    Rocco.new(filename, [], options, &block).to_html
  end
  
  def ruby2ruby(io, filename = io.path)
    ruby2ruby = Ruby2Ruby.new
    code = ruby2ruby.process ruby2sexp(io, filename)
  end
  
  def ruby2sexp(io, filename = io.path)
    parser = RubyParser.new
    parser.process(io.read, filename)
  end
end

get '/' do
  mustache :home
end

get '/f/:name' do
  content_type 'text/plain'
  file = File.open("./fixtures/#{params[:name]}.rb")
  ruby2sexp(file).pretty_inspect
end

get '/gen' do
  file = File.open(__FILE__)
  rocco("ExplainRuby.net") { ruby2ruby(file) }
end

get '/chunky.css' do
  content_type 'text/css'
  sass :style
end

get '/docco.css' do
  content_type 'text/css'
  sass :docco
end
