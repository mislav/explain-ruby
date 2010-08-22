## Attribute accessor

This method is used to expose instance variables (which otherwise can't be accessed from outside the instance) by generating "accessor" methods. Two simple methods are generated; one for reading that returns the instance variable of the same name, the other for writing that assigns a new value to the instance variable. For instance, if `attr_accessor :programming_language` was used in a "Person" class, it would expose the attribute on all its instances:

    person.programming_language
    #=> nil
    
    person.programming_language = "Ruby"
    person.programming_language
    #=> "Ruby"
    
    # attribute value is stored in "@programming_language"
    # instance variable on the "person" object
    