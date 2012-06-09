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

      define_method(method_name) do |*args, &blk|
        sig.each_with_index do |conversion_meth, index|
          arg = args[index]
          args[index] = if conversion_meth.class == Hash
                          self.class._validate_hash(arg, conversion_meth, method_name, index)
                        elsif conversion_meth.class == Array
                          self.class._validate_array(arg, conversion_meth, method_name, index)
                        else
                          self.class._validate_arg_type(arg, conversion_meth, method_name, index)
                        end
        end

        result = meth.bind(self).call(*args, &blk)
        return_proc ? return_proc.call(result) : result
      end
    end

    def _validate_hash(hash, conversion_meths, method_name, index)
      key_conversion, value_conversion = conversion_meths.to_a.flatten
      hash.reduce({}) do |new_h, (k,v)|
        converted_key = _validate_arg_type(k, key_conversion, method_name, "#{index} (key in hash)")
        converted_val = _validate_arg_type(v, value_conversion, method_name, "#{index} (value in hash)")
        new_h[converted_key] = converted_val
        new_h
      end
    end

    def _validate_array(array, conversion, method_name, index)
      array.reduce([]) do |new_a, elem|
        new_a.push(_validate_arg_type(elem, conversion.first, method_name, index))
        new_a
      end
    end

    def _validate_arg_type(arg, conversion_meth, method_name, index)
      unless arg.respond_to?(conversion_meth)
        raise "Argument #{arg.inspect} for #{self.name}##{method_name} at position #{index} does not respond to #{conversion_meth}"
      end
      arg.send(conversion_meth)
    end
  end
end
