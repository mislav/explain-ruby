## Block method argument

Every method in Ruby can take a "block", and this method indicates it explicitly by declaring a named block argument. This special argument is denoted by the `&` sign before its name, must come at the last place in the arguments list, and can only be one per method. The "block" argument is always optional; if not given it will be nil.

A "block" in Ruby is simply some Ruby code grouped together, delimited by `do ... end` keywords or, alternatively, curly brackets (`{ ... }`) following a method call. Like methods, blocks can receive arguments; the argument list is specified with pipe symbols (e.g. `|a, b, c|`) at the beginning of the block.

At execution time, the method can check if it received the block. This is done with a special language construct `block_given?`. The block can be invoked with its `call` method, e.g. `block.call(1, 2, 3)`. The values supplied will be values for block arguments, if any.