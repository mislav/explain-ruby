# Explain Ruby

[A web tool to teach Ruby][explain]. Paste code or a URL to have the syntax explained.

## How it works

While made for beginners, the tool is technologically very non-trivial. It uses ruby_parser to break down Ruby code and then ruby2ruby to reconstruct it back while adding documentation in correct places. Finally, the output is ran through Rocco to generate the pretty two-column layout.

## Problems

It is in alpha phase. The output still breaks on any code more complex than bare basic Ruby. All the documentation was done by me in a single day. So if you spot how docs can be better, please contribute to the "explanations/" directory. If you feel adventurous, the "processor.rb" (which) needs a lot of love to enable it to handle more complex Ruby code.

Report bugs as [issues on GitHub][issues].

[explain]: http://explainruby.net/
[issues]: http://github.com/mislav/explain-ruby/issues
