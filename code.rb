require 'nokogiri'
require 'ruby_parser'
require 'processor'
require 'net/http'
# TODO: SSL support
# require 'net/https'

Net::HTTPResponse.class_eval do
  def http?
    content_type == 'text/html' or content_type == 'application/xhtml+xml'
  end
end

module ExplainRuby
  module FromUrl
    def from_url(url)
      code = if raw_url = get_raw_url(url)
        get_raw_body(raw_url)
      else
        response = get_http_response(url)
        if response.html?
          extract_code_from_html(response.body)
        else
          response.body
        end
      end
      
      new(code, raw_url || url)
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
    
    def initialize(code, url = nil)
      raise ArgumentError, "no code given" if code.nil? or code.empty?
      @code = code.to_s
      @url = url.nil?? nil : url.to_s
      @reconstructed_code = nil
      @explained_code = nil
      @sexp = nil
    end
    
    def to_s
      @explained_code ||= process
    end
    
    def process
      insert_explanations reconstruct_code
    end
    
    def parse
      @sexp ||= self.class.ruby2sexp(@code, @url)
    end
    
    # delegate pretty printing to sexp
    def pretty_print(io)
      parse.pretty_print(io)
    end
    
    def reconstruct_code
      @reconstructed_code ||= self.class.ruby2ruby(parse, @url)
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
        new(file.read, file.path)
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
        code = described_class.new("class Klass < Main; end")
        code.reconstruct_code.should == ">> class class_inheritance\nclass Klass < Main\nend"
      end
      
      it "doesn't insert same marker twice" do
        code = described_class.new("def foo() 1 end; def bar() 2 end")
        code.reconstruct_code.should == ">> method\ndef foo\n  1\nend\n\ndef bar\n  2\nend\n"
      end
    end
    
    it "delegates pretty printing to sexp" do
      code = described_class.new("class Klass; end")
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
