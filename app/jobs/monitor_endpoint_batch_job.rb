class MonitorEndpointBatchJob < ApplicationJob
  queue_as :default

  def perform(endpoint_ids)
    Endpoint.where(id: endpoint_ids).find_each do |endpoint|
      next unless endpoint.enabled?
      begin
        monitor = EndpointMonitor.new(endpoint)
        result = monitor.check
        endpoint.update!(last_checked_at: Time.current)
        if endpoint.status != result[:status] || endpoint.status_changes.empty?
          endpoint.update_status!(
            result[:status],
            result[:response_time_ms],
            result[:message]
          )
          if ['down', 'degraded'].include?(result[:status])
            AlertService.new(endpoint, result).send_alerts
          end
        end
      rescue => e
        Rails.logger.error "Error monitoring endpoint \\#{endpoint.id}: \\#{e.message}"
      end
    end
  end
end