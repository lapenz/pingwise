class AlertService
  def initialize(endpoint, check_result)
    @endpoint = endpoint
    @check_result = check_result
    @user = endpoint.user
  end

  def send_alerts
    send_email_alert if email_enabled?
    send_slack_alert if slack_enabled?
    send_sms_alert if sms_enabled?
  end

  private

  def send_email_alert
    # This would integrate with your email service (SendGrid, Mailgun, etc.)
    Rails.logger.info "Email alert sent for endpoint #{@endpoint.name}: #{@check_result[:status]}"
  end

  def send_slack_alert
    return unless slack_webhook_url.present?

    notifier = Slack::Notifier.new(slack_webhook_url)
    notifier.ping(
      text: "🚨 Endpoint Alert",
      attachments: [{
        color: @check_result[:status] == 'down' ? 'danger' : 'warning',
        title: @endpoint.name,
        text: "Status: #{@check_result[:status].upcase}\nMessage: #{@check_result[:message]}",
        fields: [
          {
            title: "Response Time",
            value: @check_result[:response_time_ms] ? "#{@check_result[:response_time_ms]}ms" : "N/A",
            short: true
          },
          {
            title: "Type",
            value: @endpoint.endpoint_type.upcase,
            short: true
          }
        ],
        footer: "PingWise Monitor",
        ts: Time.current.to_i
      }]
    )
  rescue => e
    Rails.logger.error "Slack alert failed: #{e.message}"
  end

  def send_sms_alert
    return unless twilio_credentials_present?

    client = Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)
    
    message = client.messages.create(
      from: twilio_phone_number,
      to: @user.phone_number,
      body: "🚨 #{@endpoint.name} is #{@check_result[:status].upcase}: #{@check_result[:message]}"
    )
  rescue => e
    Rails.logger.error "SMS alert failed: #{e.message}"
  end

  def email_enabled?
    # Add user preference for email alerts
    true
  end

  def slack_enabled?
    slack_webhook_url.present?
  end

  def sms_enabled?
    twilio_credentials_present? && @user.phone_number.present?
  end

  def slack_webhook_url
    ENV['SLACK_WEBHOOK_URL']
  end

  def twilio_credentials_present?
    ENV['TWILIO_ACCOUNT_SID'].present? && ENV['TWILIO_AUTH_TOKEN'].present? && ENV['TWILIO_PHONE_NUMBER'].present?
  end

  def twilio_account_sid
    ENV['TWILIO_ACCOUNT_SID']
  end

  def twilio_auth_token
    ENV['TWILIO_AUTH_TOKEN']
  end

  def twilio_phone_number
    ENV['TWILIO_PHONE_NUMBER']
  end
end 