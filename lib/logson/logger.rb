module Logson
  class Logger < ::Logger
    attr_accessor :hostname

    FORMATTER = Proc.new do |severity, date, progname, msg|
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
      JSON.dump(data) + "\n"
    end.freeze

    def initialize(*args)
      super(*args)

      self.hostname = Socket.gethostname
      self.formatter = FORMATTER
    end

    def source=(value)
      self.progname = value
    end

    def source
      self.progname
    end
  end
end
