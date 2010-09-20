## `begin` statement

A `begin` statement is primarily used when a piece of code may raise an exception that we wish to `rescue` from or `ensure` that even if an exception is raised that more code is ran. An example:

     begin
       boom!
     rescue Boom => e
       puts "No more boom."
     ensure
       puts "Everything is OK."
     end
     
In this example, if the `boom!` method raises a `Boom` exception, this will be caught by the `rescue` statement which assigns the rescued exception to the local variable `e`. Everything after the `rescue` but before the following `end` or `ensure` is the code that will be ran during the `rescue`. To get the stacktrace or message of this exception we can call `stacktrace` and `message` respectively on this object. 

The `ensure` statement declares code that should be ran always, regardless of if an exception was rescued.
       