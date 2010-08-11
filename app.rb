require 'sinatra'
require 'ruby2ruby'
require 'ruby_parser'

require 'sass'
require 'mustache/sinatra'
set :mustache, { :templates => './templates', :views => './views' }
# set :haml, :format => :html5

require 'rocco'
# class Rocco::Layout < Mustache
#   self.template_path = File.dirname(__FILE__)
# end

# require 'active_support'
# require 'active_support/core_ext'
# require 'active_support/multibyte'

# named_routes = ActionController::Routing::Routes.named_routes.instance_variable_get '@module'
# sexp = ParseTree.translate named_routes, named_route
# unified = Unifier.new.process sexp
# puts Ruby2Ruby.new.process(unified)

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
    return yield
    # Rocco.new(filename, [], options, &block).to_html
  end
  
  def ruby2ruby(io, filename = io.path)
    parser    = RubyParser.new
    ruby2ruby = Ruby2Ruby.new
    sexp = parser.process(io.read, filename)
    code = ruby2ruby.process(sexp)
  end
end

get '/' do
  # content_type 'text/plain'
  # file = File.open(__FILE__)
  # rocco(file.path) { ruby2ruby(file) }
  mustache :home
end

get '/chunky.css' do
  content_type 'text/css'
  sass :style
end
