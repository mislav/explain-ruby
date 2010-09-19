require 'nokogiri'
require 'ruby_parser'
require 'processor'
require 'digest/md5'
require 'net/http'
# TODO: SSL support
# require 'net/https'

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
    extend FromUrl
    
    attr_reader :attributes
    
    def initialize(attributes)
      @attributes = attributes
      @reconstructed_code = nil
      @explained_code = nil
      @sexp = nil
    end
    
    def [](key)
      @attributes[key.to_s]
    end
    
    def []=(key, value)
      @attributes[key.to_s] = value
    end
    
    def slug() self['slug'] end
    def md5() self['md5'] end
    def url() self['url'] end
    
    class << self
      attr_accessor :mongo
    end
    
    def self.from_url(url)
      find_or('url' => url) do |params|
        create(super) { |obj| obj.attributes.update(params) }
      end
    end
    
    def self.create(code)
      md5 = md5_digest code
      
      find_or('md5' => md5) do |params|
        obj = new({'code' => code}.update(params))
        yield obj if block_given?
        obj.save
      end
    end
    
    def self.find_or(query)
      if record = mongo.find_one(query, :fields => 'slug')
        new(record)
      else
        yield query
      end
    end
    
    def self.exists?(query)
      !!mongo.find_one(query, :fields => [])
    end
    
    def self.md5_digest(code)
      Digest::MD5.hexdigest code.strip
    end
    
    def self.find(slug)
      record = mongo.find_one(:slug => slug) and new(record)
    end
    
    SEED = ('a'..'z').to_a
    
    def self.generate_slug
      (1..3).map { SEED[rand(SEED.length)] }.join('').tap do |slug|
        slug << SEED[rand(SEED.length)] while exists?(:slug => slug)
      end
    end
    
    def save
      self['md5'] ||= self.class.md5_digest(self['code'])
      self['slug'] ||= self.class.generate_slug
      self['created_at'] ||= Time.now
      self.class.mongo.save(@attributes, :safe => true)
      self
    end
    
    def to_s
      @explained_code ||= process
    end
    
    def process
      insert_explanations reconstruct_code
    end
    
    def parse
      self.class.ruby2sexp(self['code'], self['url'])
    end
    
    # delegate pretty printing to sexp
    def pretty_print(io)
      parse.pretty_print(io)
    end
    
    def reconstruct_code
      @reconstructed_code ||= self.class.ruby2ruby(parse, self['url'])
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

if $0 == __FILE__
  require 'spec/autorun'
  require 'pp'
  
  body_code, body_no_code, body_gist, body_gist_no_ruby = DATA.read.split('===')
  
  describe ExplainRuby::Code do
    describe ".get_raw_url" do
      it "translates pastie" do
        url = described_class.get_raw_url 'http://pastie.org/pastes/1234'
        url.should == 'http://pastie.org/1234.txt'
      end
      
      it "translates github" do
        url = described_class.get_raw_url 'http://github.com/mislav/nibbler/blob/master/lib/nibbler/json.rb'
        url.should == 'http://github.com/mislav/nibbler/raw/master/lib/nibbler/json.rb'
      end
      
      it "translates gist" do
        gist_url = 'http://gist.github.com/540757'
        described_class.should_receive(:get_html_document).
          with(gist_url).and_return(Nokogiri::HTML(body_gist))
        
        url = described_class.get_raw_url gist_url
        url.should == 'http://gist.github.com/raw/540/455/paperclip_defaults.rb'
      end
      
      it "fails for gist without a ruby file" do
        gist_url = 'http://gist.github.com/540757'
        described_class.should_receive(:get_html_document).
          with(gist_url).and_return(Nokogiri::HTML(body_gist_no_ruby))
        
        url = described_class.get_raw_url gist_url
        url.should be_nil
      end
      
      it "fails at unknown" do
        url = described_class.get_raw_url 'http://example.com'
        url.should be_nil
      end
    end
    
    describe ".extract_code_from_html" do
      it "skips line numbers" do
        code = described_class.extract_code_from_html body_code
        code.should == "def foo\n  bar\nend"
      end
      
      it "returns nil when no code" do
        code = described_class.extract_code_from_html body_no_code
        code.should be_nil
      end
    end
    
    describe "#reconstruct_code" do
      it "inserts explanation markers" do
        code = described_class.new('code' => "class Klass < Main; end")
        code.reconstruct_code.should == ">> class class_inheritance\nclass Klass < Main\nend"
      end
      
      it "outputs curly brackets for one lined block arguments" do
        code = described_class.new('code' => "foo { |one, two| one }")
        code.reconstruct_code.should == "foo { |one, two| one }"
      end
      
      it "outputs 'do' and 'end' for multi lined block arguments" do
        code = described_class.new('code' => "foo { |one, two| one; two }")
        code.reconstruct_code.should == "foo do |one, two|\n  one\n  two\nend"
      end
      
      it "doesn't insert same marker twice" do
        code = described_class.new('code' => "def foo() 1 end; def bar() 2 end")
        code.reconstruct_code.should == ">> method\ndef foo\n  1\nend\n\ndef bar\n  2\nend\n"
      end
    end
    
    it "delegates pretty printing to sexp" do
      code = described_class.new('code' => "class Klass; end")
      code.pretty_inspect.should == "s(:class, :Klass, nil, s(:scope))\n"
    end
  end
end

__END__
<body>
  <pre>1
2
3</pre>
  <pre>def foo
  bar
end</pre>
</body>

===

<body>
  <p>No code here</p>
</body>

===

<body>
<div class="file" id="notes.md">
  <div class="actions">
    <a href="/moo">moo</a>
    <a href="/raw/540/455/notes.md">raw</a>
  </div>
</div>
<div class="file" id="file_paperclip_defaults.rb">
  <div class="actions">
    <a href="/moo">moo</a>
    <a href="/raw/540/455/paperclip_defaults.rb">raw</a>
  </div>
</div>
</body>

===

<body>
<div class="file" id="notes.md">
  <div class="actions">
    <a href="/moo">moo</a>
    <a href="/raw/540/455/notes.md">raw</a>
  </div>
</div>
</body>
