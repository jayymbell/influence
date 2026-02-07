# frozen_string_literal: true

module AhoyHelpers
  # Stub Ahoy to prevent visit tracking during tests
  # Ahoy's middleware automatically tracks visits on every request, which can interfere with tests.
  # This helper stubs the necessary methods to prevent tracking errors.
  #
  # Usage:
  #   # In a spec
  #   before { stub_ahoy_for_request }
  #
  #   # Or inline
  #   stub_ahoy_for_request
  #   get '/some/endpoint'
  def stub_ahoy_for_request
    visit_double = double('ahoy_visit', new_visit?: false)
    ahoy_double = double('ahoy',
      visit: visit_double,
      new_visit?: false,
      set_visitor_cookie: true,
      set_visit_cookie: true,
      track: true # For when ahoy.track is called in controllers
    )
    allow_any_instance_of(ApplicationController).to receive(:ahoy).and_return(ahoy_double)
  end

  # Alternative: Stub Ahoy to allow visit tracking (if you want to test Ahoy integration)
  # This creates a real Ahoy object that can track events but won't fail on cookie setting
  def allow_ahoy_tracking
    ahoy_instance = Ahoy::Tracker.new(controller: double('controller'))
    allow_any_instance_of(ApplicationController).to receive(:ahoy).and_return(ahoy_instance)
    allow(ahoy_instance).to receive(:set_visitor_cookie)
    allow(ahoy_instance).to receive(:set_visit_cookie)
  end
end

RSpec.configure do |config|
  config.include AhoyHelpers, type: :request
end
