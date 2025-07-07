class ScheduledMonitoringJob < ApplicationJob
  queue_as :default

  def perform
    # Get all enabled endpoints that are due for checking
    endpoints = Endpoint.enabled.includes(:user).select(&:should_check_now?)
    
    Rails.logger.info "Scheduled monitoring: checking #{endpoints.count} endpoints due for monitoring"
    
    # Queue individual monitoring jobs for each endpoint that needs checking
    endpoints.each do |endpoint|
      Rails.logger.info "Queueing check for endpoint #{endpoint.id} (#{endpoint.name}) - interval: #{endpoint.formatted_interval}"
      MonitorEndpointJob.perform_later(endpoint.id)
    end
  end
end 