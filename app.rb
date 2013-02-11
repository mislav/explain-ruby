require 'sinatra'
require 'sass'
require 'dm-core'
require 'code'

set :sass, { :cache_location => File.join(ENV['TMPDIR'], '.sass-cache') }

require 'mustache/sinatra'
set :mustache, { :templates => './templates', :views => './views' }

require 'rocco_ext'

configure :development do
  ENV['DATABASE_URL'] ||= 'postgres://localhost/explainruby'
  DataMapper::Logger.new($stderr, :info)
end

configure do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  DataMapper.finalize
  DataMapper::Model.raise_on_save_failure = true
end

helpers do
  def redirect_to(code)
    redirect "/#{code.slug}"
  end
  
  def rocco(options = {}, &block)
    options = settings.rocco.merge(options)
    Rocco.new(default_title, [], options, &block).to_html
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
  if request.host == 'explainruby.heroku.com'
    redirect 'http://explainruby.net'
  else
    mustache :home
  end
end

get '/url/*' do
  code = ExplainRuby::Code.from_url params[:splat].join('')
  redirect_to code
end

post '/' do
  if not params[:url].empty?
    code = ExplainRuby::Code.from_url params[:url]
    redirect_to code
  elsif not params[:code].empty?
    code = ExplainRuby::Code.create_for_code(params[:code])
    redirect_to code
  else
    status "400 Not Chunky"
    @message = "Please paste some code or enter a URL"
    mustache :error
  end
end

get '/f/:name' do
  code = ExplainRuby::Code.from_test_fixture(params[:name])
  rocco(:url => code.url) { code.to_s }
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
  code = ExplainRuby::Code.get(params[:captures][0])
  halt 404 unless code
  etag code.code_signature
  rocco(:url => code.url) { code.to_s }
end
