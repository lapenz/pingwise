class StatusChange < ApplicationRecord
  belongs_to :endpoint

  enum :status, { up: 0, down: 1, degraded: 2, unknown: 3, paused: 4 }

  validates :status, presence: true
  validates :checked_at, presence: true
  validates :response_time_ms, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { order(checked_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :in_date_range, ->(start_date, end_date) { where(checked_at: start_date..end_date) }

  def status_changed_from_previous?
    previous_change = endpoint.status_changes.where.not(id: id).order(checked_at: :desc).first
    return true if previous_change.nil?
    previous_change.status != status
  end

  def duration_since_previous
    previous_change = endpoint.status_changes.where.not(id: id).order(checked_at: :desc).first
    return nil if previous_change.nil?
    checked_at - previous_change.checked_at
  end

  def formatted_response_time
    return "N/A" if response_time_ms.nil?
    if response_time_ms < 1000
      "#{response_time_ms.round}ms"
    else
      "#{(response_time_ms / 1000.0).round(1)}s"
    end
  end

  def formatted_duration
    return "N/A" if duration_since_previous.nil?

    duration = duration_since_previous
    if duration < 1.minute
      "#{duration.to_i}s"
    elsif duration < 1.hour
      "#{(duration / 1.minute).to_i}m"
    elsif duration < 1.day
      "#{(duration / 1.hour).to_i}h"
    else
      "#{(duration / 1.day).to_i}d"
    end
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
end
