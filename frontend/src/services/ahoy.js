import api from '../services/api'
import useUserStore from '../stores/UserStore'

export function trackEvent(name, properties = {}) {
  const userStore = useUserStore()
  
  // Only track events if user is logged in
  if (userStore.isLoggedIn && userStore.bearerToken) {
    return api.post(`/users/events`, {
      name,
      properties
    }, {
      headers: {
        'Authorization': `Bearer ${userStore.bearerToken}`
      }
    });
  }
  return Promise.resolve();
}