require 'uv'

begin
  if ENV['TMPDIR']
    original_path = ENV['PATH']
    ENV['PATH'] = ENV['TMPDIR'] + ":" + ENV['PATH']
    require 'fileutils'
    FileUtils.touch File.join(ENV['TMPDIR'], 'pygmentize')
  end
  require 'rocco'
ensure
  ENV['PATH'] = original_path if ENV['TMPDIR']
end

set :rocco, { :comment_chars => '>', :uv_style => 'dawn' }

Rocco::Layout.template_path = Sinatra::Application.mustache[:templates]
Rocco::Layout.template_name = 'rocco'

Rocco::Layout.class_eval do
  def highlight_style
    @doc.options[:uv_style]
  end
  
  def url
    @doc.options[:url]
  end
  
  def url?
    !!url
  end
end

Rocco.class_eval do
  attr_reader :options
  
  alias pygments_highlight highlight
  
  def highlight(blocks)
    docs_blocks, code_blocks = blocks

    markdown = docs_blocks.join("\n\n##### DIVIDER\n\n")
    docs_html = Markdown.new(markdown, :smart).
      to_html.
      split(/\n*<h5>DIVIDER<\/h5>\n*/m)

    all_code = code_blocks.join("\n\n# DIVIDER\n\n")
    code_html = Uv.parse(all_code, 'xhtml', 'ruby', false, options[:uv_style])

    code_html = code_html.
      split(%r{\n*<span class="Comment"><span class="Comment">#</span> DIVIDER</span>\n*}).
      each { |code| code.gsub!(%r{\s*<pre class="\w+">|</pre>}, '') }

    docs_html.zip(code_html)
  end
end
