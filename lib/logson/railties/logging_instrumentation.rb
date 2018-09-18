module Logson
  module Railties
    module LoggingInstrumentation
      extend ActiveSupport::Concern

      LOGSON_NOTIFICATIONS_HANDLERS = {
        'sql.active_record' => proc do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          Rails.logger.debug(
            message: 'sql.query',
            sql_query: event.payload[:sql].encode(
              'UTF-8', invalid: :replace, undef: :replace
            ),
            duration: event.duration,
            date: event.time
          )
        end,
        'perform_start.active_job' => proc do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          job = event.payload[:job]
          Rails.logger.debug(
            message: 'job.performing',
            date: event.time,
            duration: event.duration,
            job_id: job.job_id,
            job_arguments: job.arguments,
            job_type: job.class.to_s,
            queue_name: job.queue_name
          )
        end,
        'perform.active_job' => proc do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          data = event.payload
          job = data[:job]
          log_data = {
            message: 'job.performed',
            date: event.time,
            duration: event.duration,
            job_id: job.job_id,
            job_arguments: job.arguments,
            job_type: job.class.to_s,
            queue_name: job.queue_name,
            executions: job.executions
          }
          if data.key?(:exception)
            exception = data[:exception_object]
            Rails.logger.fatal(
              log_data.merge(
                exception_type: exception.class.to_s,
                exception_message: exception.message,
                exception_backtrace: exception.backtrace.slice(0, 10)
              )
            )
          else
            Rails.logger.debug(log_data)
          end
        end,
        'process_action.action_controller' => proc do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          data = event.payload
          request = Rack::Request.new(data[:headers].env)
          log_data = {
            date: event.time,
            duration: event.duration,
            action: request.params['action'],
            path: data[:path],
            method: data[:method],
            status: data[:status],
            source_ip: request.ip
          }
          if data.key?(:exception)
            exception = data[:exception_object]
            Rails.logger.fatal(
              log_data.merge(
                message: 'request.failed',
                exception_type: exception.class.to_s,
                exception_message: exception.message,
                exception_backtrace: exception.backtrace.slice(0, 10)
              )
            )
          else
            Rails.logger.debug(
              log_data.merge(
                message: 'request.processed',
                db_runtime: data[:db_runtime]
              )
            )
          end
        end
      }

      included do
        if defined?(Rails::Rack::Logger)
          config.middleware.delete Rails::Rack::Logger
        end

        # setup activesupport notifications handlers
        # @see LOGSON_NOTIFICATIONS_HANDLERS
        ActiveSupport::Notifications.tap do |notifications|
          LOGSON_NOTIFICATIONS_HANDLERS.each do |event_type, callback|
            notifications.subscribe(event_type, &callback)
          end
        end
      end
    end
  end
end
