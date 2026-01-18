# frozen_string_literal: true

module MailerHelpers
  def clear_mail_deliveries
    ActionMailer::Base.deliveries.clear
  end

  def last_delivery
    ActionMailer::Base.deliveries.last
  end

  def extract_confirmation_token_from_mail(mail)
    body = mail.body.to_s
    # Try URL-encoded token first
    token = body[/confirmation_token=([^\s"&>]+)/, 1]
    # Fallback to href extraction
    token ||= begin
      href = body[/href="([^"]+)"/, 1] || body[/(http[^\s>]+confirmation[^\s>]+)/, 1]
      return nil unless href
      uri = URI.parse(href)
      uri.query&.match(/confirmation_token=([^&]+)/)&.captures&.first
    end
    token
  end

  def extract_confirmation_path_from_mail(mail)
    body = mail.body.to_s
    href = body[/href="([^"]+)"/, 1] || body[/(http[^\s>]+confirmation[^\s>]+)/, 1]
    return nil unless href
    URI.parse(href).request_uri
  end
end

RSpec.configure do |config|
  config.include MailerHelpers
end
