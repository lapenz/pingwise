class MonitorEndpointJob < ApplicationJob
  queue_as :default

  def perform(endpoint_id)
    endpoint = Endpoint.find(endpoint_id)
    return unless endpoint.enabled?

    monitor = EndpointMonitor.new(endpoint)
    result = monitor.check

    # Always update the last checked timestamp first
    endpoint.update!(last_checked_at: Time.current)

    # Only update status and create status change if status changed or it's the first check
    if endpoint.status != result[:status] || endpoint.status_changes.empty?
      endpoint.update_status!(
        result[:status],
        result[:response_time_ms],
        result[:message]
      )

      # Send alerts if status is down or degraded
      if [ "down", "degraded" ].include?(result[:status])
        AlertService.new(endpoint, result).send_alerts
      end
    end
  rescue ActiveRecord::RecordNotFound
    # Endpoint was deleted, ignore
  rescue => e
    Rails.logger.error "Error monitoring endpoint #{endpoint_id}: #{e.message}"
  end
end
