module SocialBeat

class CodeLoader
  FILE_REFRESH_TIME = 0.25 # Reload the file every this many seconds

  attr_reader :file_name

  def initialize(file_name, options = {})
    @mtime = 0
    @file_name = file_name
    @instance = (options[:default_class] || Object).new
    @accum = 0

    @on_load  = options[:on_load]  || L{}
    @on_error = options[:on_error] || L{}

    load_file(@file_name)
  end

  def update(u)
    @accum += u
    if @accum >= FILE_REFRESH_TIME
      load_file(@file_name)
      @accum = 0
    end
  end

  def current_instance
    @instance
  end
  
  def self.const_missing(name)
    @@m.const_get((@@m.constants - ["Depend"]).first).const_get(name)
  end

  protected
    def load_file(file_name)
      if File.exists?(file_name)
        @changed_file = (@files || [file_name]).detect {|file| File.mtime(file).to_f > @mtime }

        if @changed_file
          mtime = File.mtime(@changed_file).to_f
          begin
            @@m = @m = m = Module.new
            m.instance_eval do
              self::const_set('Depend', [])

              def self.const_missing(name)
                const_set(name, Class.new(SocialBeat::Artist))
              end

              def self.reloadable(cls, &blk)
                parent_module = self
                (class << cls; self; end).send(:define_method, :depend) do |file|
                  parent_module::Depend << 'artists/' + file + '.rb' 

                  def self.const_missing(name)
                    const_set(name, Class.new)
                  end

                  def self.reloadable(cls, &blk)
                    cls.class_eval(&blk)
                  end

                  eval(File.read('artists/' + file + '.rb'))
                end
                cls.class_eval(&blk)
              end

              eval(File.read(file_name))
            end

            klass = m.const_get((m.constants - ["Depend"]).first)
            @mtime = mtime 
            @files = [file_name] + m::Depend
            @instance = klass.new
            @on_load[@instance]
          rescue NameError, SyntaxError, LoadError, Errno::ENOENT => e
            @on_error[e]
          end
        end
      else
        @on_error[]
      end
    end
end

end
