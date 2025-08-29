class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = true

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false

class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # Use Devise’s current_user
    self.user = controller.current_user if controller.respond_to?(:current_user)
  end
end
