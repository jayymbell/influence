import api from '../services/api'

export function trackEvent(name, properties = {}, authToken = null) {
  if (authToken) {
    return api.post(`/users/events`, {
      name,
      properties
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
  }
  return Promise.resolve();
}