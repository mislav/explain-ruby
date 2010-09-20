## :: separator

A `::` separator is used to indicate that the right-hand-side constant is defined within the scope of the left-hand-side constant. Take this for example:

    module Foo
      class Bar
    
      end
    end
   
To get to the `Bar` class we would use `::` like this: `Foo::Bar`.