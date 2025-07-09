class Endpoint < ApplicationRecord
  belongs_to :user
  has_many :status_changes, dependent: :destroy

  enum :endpoint_type, { url: 0, ip: 1, port: 2, ssl: 3, smtp: 4, dns: 5 }
  enum :status, { up: 0, down: 1, degraded: 2, unknown: 3, paused: 4 }

  validates :name, presence: true
  validates :endpoint_type, presence: true
  validates :status, presence: true
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :check_interval_seconds, numericality: { greater_than: 0, less_than_or_equal_to: 86400 }, allow_nil: true

  # Ensure at least one of url, ip, or port is provided based on endpoint_type
  validate :validate_endpoint_fields

  scope :enabled, -> { where(enabled: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(endpoint_type: type) }
  scope :due_for_check, ->(now = Time.current) {
    where(enabled: true)
      .where("last_checked_at IS NULL OR last_checked_at + (check_interval_seconds || ' seconds')::interval <= ?", now)
      .where("check_offset_bucket = ?", (now.sec / 15))
  }

  before_create :set_check_offset_bucket

  # Default interval is 60 seconds (1 minute)
  def check_interval_seconds
    self[:check_interval_seconds] || 60
  end

  def check_interval_minutes
    check_interval_seconds / 60.0
  end

  def formatted_interval
    if check_interval_seconds < 60
      "#{check_interval_seconds} seconds"
    elsif check_interval_seconds == 60
      "1 minute"
    elsif check_interval_seconds < 3600
      "#{check_interval_minutes.round(1)} minutes"
    else
      "#{(check_interval_seconds / 3600.0).round(1)} hours"
    end
  end

  def should_check_now?
    return true if last_checked_at.nil?
    Time.current >= last_checked_at + check_interval_seconds.seconds
  end

  def current_status
    status_changes.order(checked_at: :desc).first&.status || status
  end

  def last_check_at
    status_changes.order(checked_at: :desc).first&.checked_at || last_checked_at
  end

  def average_response_time
    status_changes
      .where(status: [ :up, :degraded ])
      .where.not(response_time_ms: nil)
      .average(:response_time_ms)&.round(2)
  end

  def uptime_percentage(days = 30)
    return 0 if status_changes.empty?

    total_changes = status_changes.where(checked_at: days.days.ago..Time.current).count
    up_changes = status_changes.where(status: "up", checked_at: days.days.ago..Time.current).count

    total_changes > 0 ? (up_changes.to_f / total_changes * 100).round(2) : 0
  end

  def update_status!(new_status, response_time_ms = nil, message = nil)
    return if new_status == status && status_changes.any?

    # Create status change record
    status_changes.create!(
      status: new_status,
      response_time_ms: response_time_ms,
      checked_at: Time.current,
      message: message
    )

    # Update current status only (last_checked_at is handled in the job)
    update!(status: new_status)
  end

  def status_icon
    case status
    when "up"
      "🟢"
    when "down"
      "🔴"
    when "degraded"
      "🟡"
    when "unknown"
      "⚪"
    when "paused"
      "⏸️"
    end
  end

  def timeline_segments_window(window:, now: Time.current)
    timeline_start = now - window
    last_before = status_changes.where("checked_at < ?", timeline_start).order(:checked_at).last
    # If there are no status_changes before the window, use 'unknown' as the initial status
    initial_status = last_before&.status || "unknown"
    window_changes = status_changes.where(checked_at: timeline_start..now).order(:checked_at)
    segments = []
    prev_time = timeline_start
    prev_status = initial_status
    window_changes.each do |sc|
      segment_start = prev_time
      segment_end = sc.checked_at
      segments << { status: prev_status, start: segment_start, end: segment_end } if segment_end > segment_start
      prev_time = segment_end
      prev_status = sc.status
    end
    segments << { status: prev_status, start: prev_time, end: now } if prev_time < now
    segments
  end

  def timeline_segments_24h(now = Time.current)
    timeline_segments_window(window: 24.hours, now: now)
  end

  def timeline_segments_7d(now = Time.current)
    timeline_segments_window(window: 7.days, now: now)
  end

  def smtp_port
    self[:smtp_port] || 587
  end

  private

  def status_color(status)
    case status
    when "up"
      "#10B981" # Green
    when "down"
      "#EF4444" # Red
    when "degraded"
      "#F59E0B" # Yellow
    when "unknown"
      "#6B7280" # Gray
    when "paused"
      "#3B82F6" # Blue
    else
      "#6B7280" # Gray
    end
  end

  def validate_endpoint_fields
    case endpoint_type
    when "url"
      errors.add(:url, "can't be blank for URL type") if url.blank?
    when "ip"
      errors.add(:ip, "can't be blank for IP type") if ip.blank?
    when "port"
      errors.add(:ip, "can't be blank for port type") if ip.blank?
      errors.add(:port, "can't be blank for port type") if port.blank?
    when "ssl"
      errors.add(:url, "can't be blank for SSL type") if url.blank?
    end
  end

  def set_check_offset_bucket
    self.check_offset_bucket ||= rand(0..3)
  end
end
