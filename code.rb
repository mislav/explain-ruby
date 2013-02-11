require 'nokogiri'
require 'ruby_parser'
require 'processor'
require 'digest/md5'
require 'pp'
require 'net/http'
# TODO: SSL support
# require 'net/https'
require 'dm-migrations'
require 'dm-timestamps'

Net::HTTPResponse.class_eval do
  def html?
    content_type == 'text/html' or content_type == 'application/xhtml+xml'
  end
end

module ExplainRuby
  module FromUrl
    def from_url(url)
      if raw_url = get_raw_url(url)
        get_raw_body(raw_url)
      else
        response = get_http_response(url)
        if response.html?
          extract_code_from_html(response.body)
        else
          response.body
        end
      end
    end
    
    def extract_code_from_html(doc)
      doc = Nokogiri::HTML doc unless doc.respond_to? :search
      codes = doc.search('pre').map { |p| p.inner_text }
      codes.detect { |text| text !~ /^[\s\d]+$/ }
    end
    
    def get_http_response(url)
      response = Net::HTTP.get_response URI.parse(url)
      response.error! unless Net::HTTPSuccess === response
      response
    end
    
    def get_html_document(url)
      response = get_http_response(url)
      response.error! unless response.html?
      Nokogiri::HTML response.body
    end
    
    def get_raw_body(url)
      response = get_http_response(url)
      response.error! if response.html?
      response.body
    end
  
    def get_raw_url(url)
      case url
      when %r{^(https?://pastie.org)/pastes/(\w+)$}
        url = "#{$1}/#{$2}.txt"
      when %r{^(http://github.com/[^/]+/[^/]+)/blob/(.+)$}
        url = "#{$1}/raw/#{$2}"
      when %r{^(https?://gist.github.com)/\w+$}
        prefix = $1
        doc = get_html_document(url)
        if raw_link = doc.at('.file[id$=".rb"] .actions a[href^="/raw/"]')
          raw_url = raw_link['href']
          raw_url = prefix + raw_url unless raw_url.index('http') == 0
          raw_url
        end
      else
        nil
      end
    end
  end
  
  class Code
    include DataMapper::Resource
    extend FromUrl

    property :slug,           String, :key => true
    property :code_signature, String
    property :url,            String
    property :code,           Text

    timestamps :created_at

    def code=(code)
      super
      self.code_signature = self.class.md5_digest(self.code.to_s.strip)
    end

    before :create do |entry|
      entry.slug ||= self.class.generate_slug
    end

    def self.from_url(url)
      unless entry = first(:url => url)
        entry = create_for_code(super) { |obj|
          obj.url = url
        }
      end
      entry
    end

    def self.create_for_code(code)
      md5 = md5_digest(code)
      unless entry = first(:code_signature => md5)
        entry = new(:code => code)
        yield entry if block_given?
        entry.save
      end
      entry
    end
    
    def self.md5_digest(code)
      Digest::MD5.hexdigest code.strip
    end
    
    SEED = ('a'..'z').to_a
    
    def self.generate_slug
      (1..3).map { SEED[rand(SEED.length)] }.join('').tap do |slug|
        slug << SEED[rand(SEED.length)] while all(:slug => slug).any?
      end
    end
    
    def to_s
      @explained_code ||= process
    end
    
    def process
      insert_explanations reconstruct_code
    end
    
    def parse
      self.class.ruby2sexp(code, url)
    end
    
    # delegate pretty printing to sexp
    def pretty_print(io)
      parse.pretty_print(io)
    end
    
    def reconstruct_code
      @reconstructed_code ||= self.class.ruby2ruby(parse, url)
    end
    
    EXPLANATIONS_PATH = File.expand_path('../explanations', __FILE__)
    FIXTURES_PATH = File.expand_path('../fixtures', __FILE__)
  
    def self.get_explanation(name)
      begin
        File.read(EXPLANATIONS_PATH + "/#{name}.md").strip
      rescue Errno::ENOENT
        "(No explanation for #{name})"
      end
    end
  
    def insert_explanations(code)
      code.gsub(/^\s*>>(.+)/) {
        names = $1.split
        names.map { |name| self.class.get_explanation(name) }.join("\n\n").gsub(/^/, '>')
      }
    end
  
    def self.ruby2ruby(input, filename = nil)
      filename = input.path if filename.nil? and input.respond_to? :path
      input = ruby2sexp(input, filename) unless ::Sexp === input
      ruby2ruby = Processor.new
      ruby2ruby.process input
    end
  
    def self.ruby2sexp(io, filename = io.path)
      code = io.respond_to?(:read) ? io.read : io.to_s
      parser = ::RubyParser.new
      parser.process(code, filename)
    end
    
    def self.from_test_fixture(name)
      File.open(FIXTURES_PATH + "/#{name}.rb") do |file|
        new('code' => file.read, 'url' => file.path)
      end
    end
  end
end
