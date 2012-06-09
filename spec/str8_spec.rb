require 'rspec'
require_relative '../lib/str8jacket.rb'

describe Str8jacket do
  class Testingthing
    include Str8jacket

    sig :to_int, :to_hash
    def herp(int_arg, hash_arg, *args)
      num = int_arg + 1
      hash_arg.include?('Herp')
      [num, hash_arg]
    end

    sig :to_hash
    def derp(options)
      options['cool']
    end

    sig(:to_int) { |_| _.to_a }
    def lerp(int)
      {int => nil}
    end

    sig({:to_sym => :to_s}, [:to_i]) { |_| _.to_a }
    def hash_validation(options, list_thing)
      [options, list_thing]
    end

    sig({:to_sym => :to_i}, :to_i, [:to_i]) {|_| Array(_)}
    def mom(options, random_integer_flag, random_array_arg)
      options[:something] + random_integer_flag + random_array_arg.reduce(0) {|v, n| v + n}
    end
  end

  let(:instance) { Testingthing.new }
  describe 'sig' do
    it 'validates and enforces argument types' do
      instance.herp(1, {}, 'LOL?')
      -> do
        instance.herp('a', 1)
      end.should raise_exception('Argument "a" for Testingthing#herp at position 0 does not respond to to_int')

      -> do
        instance.herp(1, 111)
      end.should raise_exception('Argument 111 for Testingthing#herp at position 1 does not respond to to_hash')

      -> do
        instance.derp({})
      end.should_not raise_exception

      -> do
        instance.derp({})
      end.should_not raise_exception
    end

    it 'validates and enforces hash and array argument types' do
      instance.hash_validation({'herp' => :derp}, ['1']).should == [{:herp => 'derp'}, [1]]
      instance.mom({'something' => '1'}, '2', ['3']).should == [6]

      -> do
        instance.hash_validation({['herp'] => :derp}, ['1'])
      end.should raise_exception('Argument ["herp"] for Testingthing#hash_validation at position 0 (key in hash) does not respond to to_sym')
    end

    it 'enforces type of return value' do
      instance.lerp(11).should == [[11,nil]]
    end
  end
end
