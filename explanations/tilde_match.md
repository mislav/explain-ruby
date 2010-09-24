`=~` operator

The `=~` operator is used when we wish to compare a string to a regular expression. The string and regular expression may be placed on either side of this operator, Ruby does not care.

If the regular expression matches the string then this operator returns the digit representing the character position of the first match, beginning from 0. If there is no match then `nil` is returned.
