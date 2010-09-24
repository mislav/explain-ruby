## `if`/`unless` statement


The `if` statement is used for when we want to conditionally run code. 

`unless` is the opposite of `if`. Where `if` will run the code if it evaluates to something that is not `nil` or `false`, `unless` will run its contained code _only_ if the condition evaluates to `nil` or `false`.

A common `if` syntax is this:

    if condition then
      conditional_code
    end

If `condition` in this example is not `nil` or `false` then the `conditional_code` will be executed. The `then` after the condition can be implicit and doesn't need to be there. Because this `if` is short, it can be all put on to one line:

    conditional_code if condition
    
You may also use the `else` keyword after the `if` but before the `end` to define code that should be ran if the `if` condition evaluates to `nil` or `false`:

    if condition
      conditional_code
    else
      alternative_code
    end

A shorter way to write this would be to use a _ternary statement_, which looks like this: 

    condition ? conditional_code : alternative_code
    
In this example the `?` indicates the beginning of the code to run when the `if` evaluates to `true`. After that code, we use `:` to denote what code should be ran if the `condition` evaluates to `false`.


**Please note**: `if` statements that can be condensed to one line will be output as ternary examples, where as multi-lined `if` statements will be output as such with `then` after the condition.
