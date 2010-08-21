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
    
      if explanations.any?
        @explained += explanations
        "\n>> #{explanations.join(' ')}\n"
      else
        "\n"
      end
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
      Sexp === exp[1] and exp[1].sexp_type == :const and also(:inheritance)
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
  
    CALLS = [:require, :attr_accessor, :attr_reader, :attr_writer, :include, :extend]
  
    def process_call(exp)
      if exp[0].nil? and CALLS.include? exp[1]
        mark(exp[1]) + super
      else
        super
      end
    end
  end
end
