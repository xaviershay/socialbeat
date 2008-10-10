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
  
  protected
    def load_file(file_name)
      if File.exists?(file_name)
        if (mtime = File.mtime(file_name).to_f) > @mtime
          begin
            m = Module.new
            m.instance_eval do
              eval(File.read(file_name))
            end

            klass = m.const_get(m.constants.first)
            @mtime = mtime 
            @instance = klass.new
            @on_load[@instance]
          rescue SyntaxError, LoadError, Errno::ENOENT
            @on_error[]
          end
        end
      else
        @on_error[]
      end
    end
end

end
