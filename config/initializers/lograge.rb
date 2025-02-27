# Only use Lograge for Rails
unless Sidekiq.server?
  filename = File.join(Rails.root, 'log', "#{Rails.env}_json.log")

  Rails.application.configure do
    config.lograge.enabled = true
    # Store the lograge JSON files in a separate file
    config.lograge.keep_original_rails_log = true
    # Don't use the Logstash formatter since this requires logstash-event, an
    # unmaintained gem that monkey patches `Time`
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.logger = ActiveSupport::Logger.new(filename)
    # Add request parameters to log output
    config.lograge.custom_options = lambda do |event|
      params = event.payload[:params]
        .except(*%w(controller action format))
        .each_pair
        .map { |k, v| { key: k, value: v } }

      payload = {
        time: Time.now.utc.iso8601(3),
        params: params,
        remote_ip: event.payload[:remote_ip],
        user_id: event.payload[:user_id],
        username: event.payload[:username],
        ua: event.payload[:ua],
        queue_duration: event.payload[:queue_duration]
      }

      gitaly_calls = Gitlab::GitalyClient.get_request_count

      if gitaly_calls > 0
        payload[:gitaly_calls] = gitaly_calls
        payload[:gitaly_duration] = Gitlab::GitalyClient.query_time_ms
      end

      rugged_calls = Gitlab::RuggedInstrumentation.query_count

      if rugged_calls > 0
        payload[:rugged_calls] = rugged_calls
        payload[:rugged_duration_ms] = Gitlab::RuggedInstrumentation.query_time_ms
      end

      payload[:response] = event.payload[:response] if event.payload[:response]
      payload[Labkit::Correlation::CorrelationId::LOG_KEY] = Labkit::Correlation::CorrelationId.current_id

      payload
    end
  end
end
