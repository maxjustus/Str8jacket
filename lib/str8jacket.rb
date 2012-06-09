module Str8jacket
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def sig(*args, &return_sig)
      @_method_signatures ||= []
      @_method_signatures << (args << return_sig)
    end

    #FIXME support singleton method signatures
    #def singleton_method_added(method_name)
    #end

    #FIXME support private and protected methods
    def method_added(method_name)
      super
      return if @_method_signatures.empty?

      sig = @_method_signatures.pop
      return_proc = sig.pop

      meth = instance_method(method_name)
      orig_arguments = meth.parameters

      define_method(method_name) do |*args, &blk|
        sig.each_with_index do |conversion, index|
          required = orig_arguments[index][0] == :req
          arg = args[index]
          args[index] = Str8jacket::Validator.new(arg, conversion, method_name, index, required).validate
        end

        result = meth.bind(self).call(*args, &blk)
        return_proc ? return_proc.call(result) : result
      end
    end
  end

  class Validator
    attr_accessor :arg, :conversion, :method_name, :index, :required
    def initialize(arg, conversion, method_name, index, required)
      @arg = arg
      @conversion = conversion
      @method_name = method_name
      @index = index
      @required = required
    end

    def validate
      if arg && required
        if conversion.class == Hash
          validate_hash
        elsif conversion.class == Array
          validate_array
        else
          validate_arg_type
        end
      end
    end

    def validate_hash
      key_conversion, value_conversion = conversion.to_a.flatten

      arg.reduce({}) do |new_h, (k,v)|
        converted_key = validate_arg_type(k, key_conversion, "(key in hash)")
        converted_val = validate_arg_type(v, value_conversion, "(value in hash)")
        new_h[converted_key] = converted_val
        new_h
      end
    end

    def validate_array
      arg.reduce([]) do |new_a, elem|
        new_a.push(validate_arg_type(elem, conversion.first))
        new_a
      end
    end

    def validate_arg_type(arg = @arg, conversion = @conversion, msg = '')
      if [String, Symbol].include?(conversion.class)
        unless arg.respond_to?(conversion)
          argument_error(arg, conversion, msg)
        end
        arg.send(conversion)
      else
        validate_arg_class(arg, conversion, msg)
      end
    end

    def validate_arg_class(arg = @arg, conversion = @conversion, msg = '')
      unless arg.is_a?(conversion)
        argument_error(arg, conversion, msg, 'is not an instance of')
      end
      arg
    end

    def argument_error(arg, conversion, type_msg, conversion_message = 'does not respond to')
      raise "Argument #{arg.inspect} #{type_msg} at position #{index} #{conversion_message} #{conversion}".split(' ').join(' ')
    end
  end
end
