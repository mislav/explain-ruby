require 'sinatra'
require 'sass'
require 'pp'
require 'code'
require 'mongo'

configure :development do
  connection = Mongo::Connection.from_uri 'mongodb://localhost'
  db = connection.db('explainruby')
  ExplainRuby::Code.mongo = db.collection('results')
end

require 'mustache/sinatra'
set :mustache, { :templates => './templates', :views => './views' }

require 'rocco_ext'

helpers do
  def email_link(email)
    "<a href='mailto:#{email}'>#{email}</a>"
  end
  
  def redirect_to(code)
    redirect "/#{code.slug}"
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

get '/url/*:url' do
  code = ExplainRuby::Code.from_url params[:url]
  redirect_to code
end

post '/' do
  if not params[:url].empty?
    code = ExplainRuby::Code.from_url params[:url]
    redirect_to code
  elsif not params[:code].empty?
    code = ExplainRuby::Code.create params[:code]
    redirect_to code
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

get '/explain.css' do
  sass_with_caching :explain
end

get '/docco.css' do
  sass_with_caching :docco
end

get %r!^/([a-z0-9]{3,})$! do
  code = ExplainRuby::Code.find params[:captures][0]
  halt 404 unless code
  etag code.md5
  rocco { code.to_s }
end
