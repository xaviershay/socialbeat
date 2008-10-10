require 'spec/spec_helper'
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
        file = new_foo_file!
        loader = SocialBeat::CodeLoader.new(file.path)

        File.open(file.path, 'w') {|f| f.write(fake_class('bar')) }
        loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)
        loader.current_instance.what.should == 'bar'
      end

      it 'calls the on_load method with the new instance' do
        obj = nil
        test_lambda = L{|instance| obj = instance}

        file = new_foo_file!

        loader = SocialBeat::CodeLoader.new(file.path, :on_load => test_lambda)
        File.open(file.path, 'w') {|f| f.write(fake_class('bar')) }
        loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)

        obj.should_not be_nil
        obj.what.should == 'bar'
      end

      it 'calls the on_error method and keeps the old instance if the file has a syntax error' do
        called = false 
        test_lambda = L{ called = true }

        file = new_foo_file!

        loader = SocialBeat::CodeLoader.new(file.path, :on_error => test_lambda)
        File.open(file.path, 'w') {|f| f.write(fake_class('ba"r')) }
        loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)

        called.should == true
        loader.current_instance.what.should == 'foo'
      end
    end

    describe 'when file refresh time has elapsed and file does not exist' do
      it 'calls the on_error method and keeps the old instance' do
        called = false 
        test_lambda = L{ called = true }

        file = new_foo_file!

        loader = SocialBeat::CodeLoader.new(file.path, :on_error => test_lambda)
        file.unlink
        loader.update(SocialBeat::CodeLoader::FILE_REFRESH_TIME + 1)

        called.should == true
        loader.current_instance.what.should == 'foo'
      end
    end
  end
end
