Rails.application.config.action_dispatch.default_headers = {
  # HSTS - Force HTTPS
  'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
  
  # Prevent clickjacking
  'X-Frame-Options' => 'DENY',
  
  # XSS protection
  'X-XSS-Protection' => '1; mode=block',
  
  # Prevent MIME type sniffing
  'X-Content-Type-Options' => 'nosniff',
  
  # Referrer policy
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  
  # Content Security Policy
  'Content-Security-Policy' => [
    "default-src 'self'",
    "img-src 'self' data: https:",
    "font-src 'self' https: data:",
    "style-src 'self' https: 'unsafe-inline'",
    "script-src 'self'",
    "connect-src 'self'",
    "frame-ancestors 'none'"
  ].join('; '),
  
  # Permissions Policy (formerly Feature-Policy)
  'Permissions-Policy' => [
    'camera=()',
    'microphone=()',
    'geolocation=()',
    'payment=()',
    'usb=()',
    'magnetometer=()',
    'accelerometer=()'
  ].join(', ')
}