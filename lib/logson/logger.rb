module Logson
  class Logger < ::Logger
    attr_accessor :hostname

    def initialize(*args)
      super(*args)

      self.hostname = Socket.gethostname
      self.formatter = proc do |severity, date, progname, msg|
        date = date.utc.iso8601 if date.is_a?(Time)
        data = {
          '_severity' => severity, '_date' => date, '_source' => progname,
          '_host' => hostname
        }
        if msg.is_a?(Hash)
          data = data.merge(msg)
        else
          data['message'] = msg
        end
        JSON.dump(data)
      end
    end

    def source=(value)
      self.progname = value
    end

    def source
      self.progname
    end
  end
end
