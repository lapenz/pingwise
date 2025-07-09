class EndpointMonitor
  include HTTParty

  def initialize(endpoint)
    @endpoint = endpoint
  end

  def check
    case @endpoint.endpoint_type
    when "url"
      check_url
    when "ip"
      check_ip
    when "port"
      check_port
    when "ssl"
      check_ssl
    when "smtp"
      check_smtp
    when "dns"
      check_dns
    when "page_speed"
      check_page_speed
    else
      { status: "unknown", response_time_ms: nil, message: "Unknown endpoint type" }
    end
  rescue => e
    { status: "down", response_time_ms: nil, message: "Error: #{e.message}" }
  end

  private

  def check_url
    start_time = Time.current
    response = self.class.get(@endpoint.url)
    response_time = ((Time.current - start_time) * 1000).round(2)

    if response.success?
      status = response_time > 5000 ? "degraded" : "up"
      { status: status, response_time_ms: response_time, message: "HTTP #{response.code}" }
    else
      { status: "down", response_time_ms: nil, message: "HTTP #{response.code}" }
    end
  rescue Net::ReadTimeout, Net::OpenTimeout
    { status: "down", response_time_ms: nil, message: "Timeout" }
  rescue SocketError, Errno::ECONNREFUSED
    { status: "down", response_time_ms: nil, message: "Connection refused" }
  end

  def check_ip
    require "net/ping"

    ping = Net::Ping::External.new(@endpoint.ip)
    success = ping.ping?
    response_time = if success && ping.duration && ping.duration > 0
      (ping.duration * 1000).round(2)
    else
      nil
    end

    if success
      status = response_time && response_time > 1000 ? "degraded" : "up"
      { status: status, response_time_ms: response_time, message: "Ping successful" }
    else
      { status: "down", response_time_ms: nil, message: "Ping failed" }
    end
  rescue => e
    { status: "down", response_time_ms: nil, message: "Ping error: #{e.message}" }
  end

  def check_port
    require "socket"

    start_time = Time.current
    socket = TCPSocket.new(@endpoint.ip, @endpoint.port)
    socket.close
    response_time = ((Time.current - start_time) * 1000).round(2)

    status = response_time > 2000 ? "degraded" : "up"
    { status: status, response_time_ms: response_time, message: "Port #{@endpoint.port} open" }
  rescue Errno::ECONNREFUSED
    { status: "down", response_time_ms: nil, message: "Port #{@endpoint.port} closed" }
  rescue => e
    { status: "down", response_time_ms: nil, message: "Port check error: #{e.message}" }
  end

  def check_ssl
    require "socket"
    require "openssl"
    host = URI(@endpoint.url).host
    port = URI(@endpoint.url).port || 443
    start_time = Time.current
    tcp_client = TCPSocket.new(host, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
    ssl_client.hostname = host if ssl_client.respond_to?(:hostname=)
    ssl_client.connect
    cert = ssl_client.peer_cert
    ssl_client.sysclose
    tcp_client.close
    response_time = ((Time.current - start_time) * 1000).round(2)
    if cert.nil?
      return { status: "down", response_time_ms: response_time, message: "No SSL certificate presented" }
    end
    days_until_expiry = (cert.not_after - Time.current) / 1.day
    if cert.not_after < Time.current
      { status: "down", response_time_ms: response_time, message: "SSL certificate expired" }
    elsif days_until_expiry < 30
      { status: "degraded", response_time_ms: response_time, message: "SSL expires in #{days_until_expiry.to_i} days" }
    else
      status = response_time > 3000 ? "degraded" : "up"
      { status: status, response_time_ms: response_time, message: "SSL valid for #{days_until_expiry.to_i} days" }
    end
  rescue OpenSSL::SSL::SSLError => e
    { status: "down", response_time_ms: nil, message: "SSL error: #{e.message}" }
  rescue => e
    { status: "down", response_time_ms: nil, message: "SSL check error: #{e.message}" }
  end

  def check_smtp
    require 'net/smtp'
    start_time = Time.current
    host = @endpoint.smtp_host
    port = @endpoint.smtp_port || 587
    use_tls = @endpoint.smtp_use_tls
    message = ""
    status = "up"
    Net::SMTP.start(host, port, "localhost") do |smtp|
      if use_tls
        begin
          smtp.enable_starttls
          message = "STARTTLS supported"
        rescue
          status = "degraded"
          message = "STARTTLS not supported"
        end
      else
        message = "Connected"
      end
    end
    response_time = ((Time.current - start_time) * 1000).round(2)
    { status: status, response_time_ms: response_time, message: message }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { status: "down", response_time_ms: nil, message: "Timeout" }
  rescue Errno::ECONNREFUSED
    { status: "down", response_time_ms: nil, message: "Connection refused" }
  rescue => e
    { status: "down", response_time_ms: nil, message: "SMTP error: #{e.message}" }
  end

  def check_dns
    require 'resolv'
    start_time = Time.current
    hostname = @endpoint.dns_hostname
    begin
      ip = Resolv.getaddress(hostname)
      response_time = ((Time.current - start_time) * 1000).round(2)
      { status: "up", response_time_ms: response_time, message: "Resolved to #{ip}" }
    rescue Resolv::ResolvError => e
      { status: "down", response_time_ms: nil, message: "DNS error: #{e.message}" }
    rescue => e
      { status: "down", response_time_ms: nil, message: "DNS check error: #{e.message}" }
    end
  end

  def check_page_speed
    require "open3"
    require "json"
    start_time = Time.current
    script_path = Rails.root.join("scripts", "page_speed_check.js")
    url = @endpoint.url
    begin
      stdout, stderr, status = Open3.capture3("node", script_path.to_s, url)
      if status.success?
        result = JSON.parse(stdout)
        response_time = ((Time.current - start_time) * 1000).round(2)
        load_time = result["loadTime"] || 0
        fcp = result["firstContentfulPaint"] || 0
        lcp = result["largestContentfulPaint"] || 0
        if load_time > 5000 || fcp > 2000 || lcp > 4000
          status = "degraded"
        else
          status = "up"
        end
        message = "Load: #{load_time}ms, FCP: #{fcp}ms, LCP: #{lcp}ms"
        { status: status, response_time_ms: response_time, message: message }
      else
        { status: "down", response_time_ms: nil, message: "Page speed check failed: #{stderr}" }
      end
    rescue => e
      { status: "down", response_time_ms: nil, message: "Page speed error: #{e.message}" }
    end
  end
end
