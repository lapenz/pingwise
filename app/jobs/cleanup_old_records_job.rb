class CleanupOldRecordsJob < ApplicationJob
  queue_as :default

  def perform
    # Keep status changes for 90 days
    cutoff_date = 90.days.ago

    deleted_count = StatusChange.where("checked_at < ?", cutoff_date).delete_all

    Rails.logger.info "Cleanup: deleted #{deleted_count} old status change records"
  end
end
