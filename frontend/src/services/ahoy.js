import api from '../services/api'

export function trackEvent(name, properties = {}) {
  return api.post(`/users/events`, {
    name,
    properties
  });
}