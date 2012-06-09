An experiment in adding optional type signatures to ruby methods.
================================================================

If an argument responds to type conversion from signature, it will convert the argument to that type.
If the argument doesn't respond to the given type conversion, an exception is thrown.
Return values can be converted using block passed to sig method.

    class Herp
      include Str8jacket

      sig({:to_sym => :to_i}, :to_i, [:to_i]) {|_| Array(_)}
      def mom(options, random_integer_flag, random_array_arg)
        options[:something] + random_integer_flag + random_array_arg.reduce(0) {|v, n| v + n}
      end
    end

    Herp.new.mom({'something' => '1'}, '2', ['3']) == [6]
    #=> true

    Herp.new.mom({['wat'] => '1'}, '2', ['3'])
    #=> raises an exception with the details regarding failed conversion
