class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @endpoints = current_user.endpoints.enabled.order(:name)
    @total_endpoints = @endpoints.count
    @up_endpoints = @endpoints.by_status('up').count
    @down_endpoints = @endpoints.by_status('down').count
    @degraded_endpoints = @endpoints.by_status('degraded').count

    @recent_status_changes = current_user.endpoints.joins(:status_changes)
                                        .includes(:status_changes)
                                        .where(status_changes: { checked_at: 24.hours.ago..Time.current })
                                        .order('status_changes.checked_at DESC')
                                        .limit(10)

    @endpoints_by_type = current_user.endpoints.enabled.group(:endpoint_type).count
    @average_response_times = @endpoints.map { |ep| [ep.name, ep.average_response_time] }.to_h
  end
end
