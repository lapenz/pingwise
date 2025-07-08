class ScheduledMonitoringJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform
    # Get all enabled endpoints that are due for checking
    endpoints = Endpoint.due_for_check.includes(:user)

    Rails.logger.info "Scheduled monitoring: checking #{endpoints.count} endpoints due for monitoring"

    # Enqueue batch jobs
    endpoints.map(&:id).each_slice(BATCH_SIZE) do |endpoint_ids|
      Rails.logger.info "Queueing batch check for endpoint IDs: #{endpoint_ids.inspect}"
      MonitorEndpointBatchJob.perform_later(endpoint_ids)
    end
  end
end
