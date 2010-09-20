require 'ruby2ruby'
require 'set'

module ExplainRuby
  class Processor < ::Ruby2Ruby
    def initialize
      super
      @explained = Set.new
      @also = []
    end
  
    def also(explanation)
      @also << explanation
    end
  
    def mark(*explanations)
      explanations.concat @also
      @also.clear
      explanations.reject! { |e| @explained.include? e }
    
      if explanations.any? and context_ok?
        @explained += explanations
        ">> #{explanations.join(' ')}\n"
      elsif not in_args?
        # "\n#{context.inspect}\n"
        "\n"
      else
        ""
      end
    end
    
    def context_ok?
      ( context[1].nil? or
        context[1] == :block or
        context[1, 2] == [:scope, :sclass] or
        context[1, 2] == [:scope, :module] ) and
        not in_args?
    end
    
    def in_args?
      context.include? :args
    end
  
    def process_block(exp)
      super.sub(/\A\s*\n/, '')
    end
  
    def process_scope(exp)
      super.sub(/\A\s*\n/, '')
    end
  
    def process_sclass(exp)
      exp.first.sexp_type == :self and also(:class_self)
      mark + super
    end
  
    def process_class(exp)
      Sexp === exp[1] and exp[1].sexp_type == :const and also(:class_inheritance)
      mark(:class) + super
    end
  
    def process_module(exp)
      mark(:module) + super
    end
  
    def process_defn(exp)
      case exp.first.to_s
      when 'initialize' then also(:class_initializer)
      when /=$/ then also(:method_setter)
      when /\?$/ then also(:method_predicate)
      when /!$/ then also(:method_bang)
      end
    
      if args_code_block = exp[1].find_node(:block)
        assignments = args_code_block.find_nodes(:lasgn)
        also(:method_default_arguments) if assignments.any?
      end
    
      exp[1].sexp_body.any? { |name| name.to_s =~ /^&/ } and also(:method_block)
    
      mark(:method) + super
    end
  
    def process_defs(exp)
      also(:class_method)
      super
    end
  
    def process_begin(exp)
      mark(:begin) + super
    end
  
    def process_case(exp)
      mark(:case) + super
    end
  
    def process_cdecl(exp)
      mark(:constant) + super
    end
  
    def process_lasgn(exp)
      if [:masgn, :iter].include?(context[1]) 
        super
      else
        mark(:variable_local) + super
      end
    end
  
    def process_iasgn(exp)
      mark(:variable_instance) + super
    end
  
    def process_cvdecl(exp)
      mark(:variable_class) + super
    end
    
    def process_if(exp)
      mark(:if) + super
    end
    
    # ::Foo
    def process_colon3(exp)
      mark(:colon3) + super
    end
    
    # defined?(a)
    # defined?(Constant)
    def process_defined(exp)
      mark(:defined) + super
    end
    
    # Literal values are objects that are:
    # Numeric
    # Symbol
    # Range
    # And maybe more
    def process_lit(exp)
      case exp[0]
        # A range
      when /^.*?\.\.\.?.*?$/
        mark(:range) + super
      else
        super
      end
    end

    # Stolen from within Ruby2Ruby
    # Massacred to remove the useless do after the collection
    def process_for(exp)
      recv = process exp.shift
      iter = process exp.shift
      body = exp.empty? ? nil : process(exp.shift)

      result = ["for #{iter.gsub("\n", "")} in #{recv}"]
      result << indent(body ? body : "# do nothing")
      result << "end"

      mark(:for) + result.join("\n")
    end
    
    # "string" =~ /regex/
    def process_match3(exp)
      mark(:tilde_match) + super
    end

    alias_method :process_match2, :process_match3

    CALLS = [:require, :attr_accessor, :attr_reader, :attr_writer, :include, :extend]
    SPECIALS = [:colon2]
  
    def process_call(exp)
      if exp[0].nil? and CALLS.include? exp[1]
        mark(exp[1]) + super
      elsif !exp[0].nil? and SPECIALS.include? exp[0][0]
        mark(exp[0][0]) + super
      # All this crap for string interpolation.
      elsif exp[2] && exp[2][1] && exp[2][1].sexp_type == :dstr
        if !exp[2][1].find_nodes(:evstr).empty? 
          mark(:interpolation) + super
        end
      else
        super
      end
    end
  end
end
