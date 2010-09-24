## Range definition

By using `..` between two values, Ruby will define an _inclusive_ `Range` object. That is to say that if this is done:

    "a".."z"
    
All letters from a through z will be included in this `Range` object. If you only want everything until the last value, use `...` like this:

    "a"..."z"
    
This will return the letters a-y.