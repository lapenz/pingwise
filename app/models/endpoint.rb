class Endpoint < ApplicationRecord
  belongs_to :user
  has_many :status_changes, dependent: :destroy

  enum :endpoint_type, { url: 0, ip: 1, port: 2, ssl: 3 }
  enum :status, { up: 0, down: 1, degraded: 2, unknown: 3, paused: 4 }

  validates :name, presence: true
  validates :endpoint_type, presence: true
  validates :status, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :check_interval_seconds, numericality: { greater_than: 0, less_than_or_equal_to: 86400 }, allow_nil: true
  
  # Ensure at least one of url, ip, or port is provided based on endpoint_type
  validate :validate_endpoint_fields
  
  scope :enabled, -> { where(enabled: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(endpoint_type: type) }

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
      .where(status: [:up, :degraded])
      .where.not(response_time_ms: nil)
      .average(:response_time_ms)&.round(2)
  end

  def uptime_percentage(days = 30)
    return 0 if status_changes.empty?
    
    total_changes = status_changes.where(checked_at: days.days.ago..Time.current).count
    up_changes = status_changes.where(status: 'up', checked_at: days.days.ago..Time.current).count
    
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
    when 'up'
      '🟢'
    when 'down'
      '🔴'
    when 'degraded'
      '🟡'
    when 'unknown'
      '⚪'
    when 'paused'
      '⏸️'
    end
  end

  def timeline_data(days = 7, segment_hours = 1)
    end_time = Time.current
    start_time = days.days.ago.beginning_of_day
    
    # Get all status changes in the time range in a single query
    changes_in_range = status_changes
      .where(checked_at: start_time..end_time)
      .order(:checked_at)
      .pluck(:status, :checked_at, :message)
    
    # If no status changes, return simple data with current status
    if changes_in_range.empty?
      # Use larger segments for better performance
      segment_count = [days * 24 / segment_hours, 168].min # Max 168 segments (7 days * 24 hours)
      segment_seconds = (end_time - start_time) / segment_count
      
      segments = []
      segment_count.times do |i|
        segment_start = start_time + (i * segment_seconds)
        segment_end = start_time + ((i + 1) * segment_seconds)
        
        segments << {
          status: status,
          start_time: segment_start,
          end_time: segment_end,
          duration_percent: 100.0 / segment_count,
          change_time: nil,
          change_message: nil
        }
      end
      
      return { segments: segments, total_duration: end_time - start_time }
    end
    
    # Create segments based on actual status changes rather than fixed time intervals
    segments = []
    current_status = status
    current_time = start_time
    total_duration = end_time - start_time
    
    changes_in_range.each_with_index do |(change_status, change_time, change_message), index|
      # Add segment from current_time to this change
      if change_time > current_time
        duration = change_time - current_time
        duration_percent = (duration / total_duration) * 100
        
        segments << {
          status: current_status,
          start_time: current_time,
          end_time: change_time,
          duration_percent: duration_percent,
          change_time: nil,
          change_message: nil
        }
      end
      
      # Add segment for the change itself
      next_change_time = changes_in_range[index + 1]&.second || end_time
      duration = next_change_time - change_time
      duration_percent = (duration / total_duration) * 100
      
      segments << {
        status: change_status,
        start_time: change_time,
        end_time: next_change_time,
        duration_percent: duration_percent,
        change_time: change_time,
        change_message: change_message
      }
      
      current_status = change_status
      current_time = next_change_time
    end
    
    # If we haven't covered the full time range, add a final segment
    if current_time < end_time
      duration = end_time - current_time
      duration_percent = (duration / total_duration) * 100
      
      segments << {
        status: current_status,
        start_time: current_time,
        end_time: end_time,
        duration_percent: duration_percent,
        change_time: nil,
        change_message: nil
      }
    end
    
    # Limit segments to prevent overwhelming the UI
    max_segments = 168 # Max 168 segments
    if segments.length > max_segments
      # Merge segments to reduce count while preserving important changes
      merged_segments = []
      segment_group_size = (segments.length.to_f / max_segments).ceil
      
      segments.each_slice(segment_group_size) do |group|
        if group.length == 1
          merged_segments << group.first
        else
          # Merge group into single segment, use most recent status
          total_duration_percent = group.sum { |s| s[:duration_percent] }
          merged_segments << {
            status: group.last[:status],
            start_time: group.first[:start_time],
            end_time: group.last[:end_time],
            duration_percent: total_duration_percent,
            change_time: group.last[:change_time],
            change_message: group.last[:change_message]
          }
        end
      end
      segments = merged_segments
    end
    
    { segments: segments, total_duration: total_duration }
  end

  private

  def status_color(status)
    case status
    when 'up'
      '#10B981' # Green
    when 'down'
      '#EF4444' # Red
    when 'degraded'
      '#F59E0B' # Yellow
    when 'unknown'
      '#6B7280' # Gray
    when 'paused'
      '#3B82F6' # Blue
    else
      '#6B7280' # Gray
    end
  end

  def validate_endpoint_fields
    case endpoint_type
    when 'url'
      errors.add(:url, "can't be blank for URL type") if url.blank?
    when 'ip'
      errors.add(:ip, "can't be blank for IP type") if ip.blank?
    when 'port'
      errors.add(:ip, "can't be blank for port type") if ip.blank?
      errors.add(:port, "can't be blank for port type") if port.blank?
    when 'ssl'
      errors.add(:url, "can't be blank for SSL type") if url.blank?
    end
  end
end
