class EndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_endpoint, only: [ :show, :edit, :update, :destroy, :check_now ]

  def index
    @endpoints = current_user.endpoints.order(:name)
    @status_counts = {
      up: @endpoints.by_status("up").count,
      down: @endpoints.by_status("down").count,
      degraded: @endpoints.by_status("degraded").count,
      unknown: @endpoints.by_status("unknown").count,
      paused: @endpoints.by_status("paused").count
    }
  end

  def show
    @status_changes = @endpoint.status_changes.recent.limit(20)
    @uptime_30d = @endpoint.uptime_percentage(30)
    @uptime_7d = @endpoint.uptime_percentage(7)
    @uptime_24h = @endpoint.uptime_percentage(1)

    # Timeline data for D3 chart - last 24 hours of status changes
    @timeline_events = @endpoint.status_changes
      .where(checked_at: 24.hours.ago..Time.current)
      .order(:checked_at)
      .pluck(:status, :checked_at, :message)
      .map { |status, checked_at, message|
        {
          status: status,
          checked_at: checked_at.iso8601,
          message: message
        }
      }

    # Timeline data for last 10 days
    @timeline_events_10d = @endpoint.status_changes
      .where(checked_at: 10.days.ago..Time.current)
      .order(:checked_at)
      .pluck(:status, :checked_at, :message)
      .map { |status, checked_at, message|
        {
          status: status,
          checked_at: checked_at.iso8601,
          message: message
        }
      }
  end

  def new
    @endpoint = current_user.endpoints.build
  end

  def create
    @endpoint = current_user.endpoints.build(endpoint_params)
    @endpoint.status = "unknown"

    if @endpoint.save
      redirect_to @endpoint, notice: "Endpoint was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @endpoint.update(endpoint_params)
      redirect_to @endpoint, notice: "Endpoint was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @endpoint.destroy
    redirect_to endpoints_url, notice: "Endpoint was successfully deleted."
  end

  def check_now
    MonitorEndpointJob.perform_later(@endpoint.id)
    redirect_to @endpoint, notice: "Endpoint check has been queued."
  end

  private

  def set_endpoint
    @endpoint = current_user.endpoints.find(params[:id])
  end

  def endpoint_params
    params.require(:endpoint).permit(:name, :endpoint_type, :url, :ip, :port, :enabled, :check_interval_seconds, :smtp_host, :smtp_port, :smtp_use_tls)
  end
end
