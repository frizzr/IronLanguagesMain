require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.9' do
  describe "Kernel#define_singleton_method" do
    describe "when given an UnboundMethod" do
      class DefineSingletonMethodSpecClass
        MY_CONST = 42
        define_singleton_method(:another_test_method, self.method(:constants))
      end

      it "correctly calls the new method" do
        klass = DefineSingletonMethodSpecClass
        klass.another_test_method.should == klass.constants
      end

      it "adds the new method to the methods list" do
        DefineSingletonMethodSpecClass.should have_method(:another_test_method)
      end

      ruby_bug "redmine:2117", "1.8.7" do
        it "defines any Child class method from any Parent's class methods" do
          um = KernelSpecs::Parent.method(:parent_class_method).unbind
          KernelSpecs::Child.send :define_singleton_method, :child_class_method, um
          KernelSpecs::Child.child_class_method.should == :foo
          lambda{KernelSpecs::Parent.child_class_method}.should raise_error(NoMethodError)
        end

        it "will raise when attempting to define an object's singleton method from another objetc's singleton method" do
          other = KernelSpecs::Parent.new
          p = KernelSpecs::Parent.new
          class << p
            def singleton_method
              :single
            end
          end
          um = p.method(:singleton_method).unbind
          lambda{ other.send :define_singleton_method, :other_singleton_method, um }.should raise_error(TypeError)
        end
      end

    end

    it "defines a new method with the given name and the given block as body in self" do
      class DefineSingletonMethodSpecClass
        define_singleton_method(:block_test1) { self }
        define_singleton_method(:block_test2, &lambda { self })
      end
    
      o = DefineSingletonMethodSpecClass
      o.block_test1.should == o
      o.block_test2.should == o
    end
  
    it "raises a TypeError when the given method is no Method/Proc" do
      lambda {
        Class.new { define_singleton_method(:test, "self") }
      }.should raise_error(TypeError)
    
      lambda {
        Class.new { define_singleton_method(:test, 1234) }
      }.should raise_error(TypeError)
    end
  
    it "defines a new singleton method for objects" do
      s = "hello"
      s.define_singleton_method(:test) { "world!" }
      s.test.should == "world!"
      lambda {
        "hello".test
      }.should raise_error(NoMethodError)
    end

    it "maintains the Proc's scope" do
      class DefineMethodByProcClass
        in_scope = true
        method_proc = proc { in_scope }
      
        define_singleton_method(:proc_test, &method_proc)
      end
    
      DefineMethodByProcClass.proc_test.should == true
    end
  end
end