module AuthHelpers
  def sign_in(user = nil)
    user ||= create(:user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    user
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
