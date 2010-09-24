## `case` statement

A `case` statement is used for when you want to act on a returned value that could be one of many different values. The value passed to the `case` statement is the value which is being checked. The `when` statements inside the case use a triple-equal (`===`) call to determine if the two objects are equal, using the value from the `when` as the left-hand side of the operation and the value from the `case` as the right-hand side. 

This triple-equal sign is how you may check to see if the specified object is of a specific type:

    >> String === "a"
    => true