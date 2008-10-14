require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')
require 'socialbeat/code_loader'

require 'tempfile'

describe SocialBeat::CodeLoader do
  describe '#file_name' do
    it 'returns the file_name passed into the initializer' do
      SocialBeat::CodeLoader.new('bogus').file_name.should == 'bogus'
    end
  end

  describe '#current_instance' do
    it 'is initialized to a new Object if no default is provided' do
      SocialBeat::CodeLoader.new('').current_instance.class.should == Object
    end

    it 'is initialized to a new instance of :default_class' do
      klass = Class.new 
      SocialBeat::CodeLoader.new('', :default_class => klass).current_instance.class.should == klass
    end
  end

  describe '#update' do
    def fake_class(ret)
      ret = <<-EOS
        class self::Foo
          def what
            "#{ret}"
          end
        end
      EOS
    end

    def new_foo_file!
      file = Tempfile.new('social_beat_test')
      File.open(file.path, 'w') {|f| f.write(fake_class('foo')) }
      file
    end

    def load_class(src, options = {})
      file = new_foo_file!

      loader = SocialBeat::CodeLoader.new(file.path, 
        :on_load  => (options[:on_load]  || L{}).to_proc,
        :on_error => (options[:on_error] || L{}).to_proc
      )
      File.open(file.path, 'w') {|f| f.write(src) }
      loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)
      loader
    end


    it 'accumulates the passed u time until FILE_REFRESH_TIME is elapsed' do
      File.stub!(:mtime).and_return(*(1..10000).to_a) 
      file = new_foo_file!
      kount = 0
      loader = SocialBeat::CodeLoader.new(file.path, :on_load => L{ kount += 1}) 
      inc = L{ loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME / 5.0) }

      kount = 0
      4.times(&inc)
      kount.should == 0
      inc.call
      kount.should == 1
      inc.call
      kount.should == 1
    end 

    describe 'when file refresh time has elapsed and file has been modified' do
      setup do
        # TODO: It appears mtime only has a resolution of 1 second, investigate
        File.stub!(:mtime).and_return(*(1..10000).to_a) 
      end

      it 'reloads class file and stores a new instance of the class' do
        loader = load_class(fake_class('bar'))
        loader.current_instance.what.should == 'bar'
      end

      it 'calls the on_load method with the new instance' do
        on_load = ExecutedCounter.new(L{|instance| 
          instance.what.shoud == 'bar'
        })

        load_class(fake_class('bar'), :on_load => on_load)
        on_load.should be_called
      end

      describe 'when the file has a syntax error' do
        it 'passes the exception to the on_error method' do
          on_error = ExecutedCounter.new(L{|exception|
              exception.class.should == SyntaxError
          })

          load_class(fake_class('bar"r'), :on_error => on_error)

          on_error.should be_called
        end

        it 'keeps the old instance' do
          loader = load_class(fake_class('bar"r'))
          loader.current_instance.what.should == 'foo'
        end
      end

      describe 'when the file has a name error' do
        setup do
          @src = "a = invalid"
        end

        it 'passes the exception to the on_error method' do
          on_error = ExecutedCounter.new(L{|exception|
              exception.class.should == NameError
          })

          load_class(@src, :on_error => on_error)

          on_error.should be_called
        end

        it 'keeps the old instance' do
          loader = load_class(@src)
          loader.current_instance.what.should == 'foo'
        end
      end
    end

    describe 'when file refresh time has elapsed and file does not exist' do
      it 'calls the on_error method and keeps the old instance' do
        file = new_foo_file!
        on_error = ExecutedCounter.new(L{})

        loader = SocialBeat::CodeLoader.new(file.path, :on_error => on_error.to_proc)
        file.unlink
        loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)

        on_error.should be_called
        loader.current_instance.what.should == 'foo'
      end
    end
  end
end
