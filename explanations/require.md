## `require` method

The `require` method loads external code. It scans the `$LOAD_PATH` array of filesystem paths and loads the first matching file found in one of the paths. The method will never load a ruby script on the same path more than once, and the ".rb" file extension is usually omitted.

By default, the "load path" array includes the standard library of the current ruby installation, but the `require` method can also be used to load 3rd-party libraries through package managers such as [RubyGems][].

[rubygems]: http://rubygems.org