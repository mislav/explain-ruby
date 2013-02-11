require 'spec/autorun'
require 'code'

DataMapper.setup(:default, ENV['DATABASE_URL'])
DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true

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

  describe "explains" do
    it "ternary statements" do
      code = described_class.new('code' => 'this ? that : them')
      code.reconstruct_code.should == ">> if\nthis ? (that) : (them)"
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
