import api from './api'

const issuesApi = {
  getAll(params = {}) {
    return api.get('/issues', { params })
  },

  get(id) {
    return api.get(`/issues/${id}`)
  },

  create(data) {
    return api.post('/issues', { issue: data })
  },

  update(id, data) {
    return api.patch(`/issues/${id}`, { issue: data })
  },

  destroy(id) {
    return api.delete(`/issues/${id}`)
  },

  close(id) {
    return api.post(`/issues/${id}/close`)
  },

  deactivate(id) {
    return api.post(`/issues/${id}/deactivate`)
  },

  reactivate(id) {
    return api.post(`/issues/${id}/reactivate`)
  },

  // Clients (sharing)
  getClients(issueId) {
    return api.get(`/issues/${issueId}/clients`)
  },

  shareWithClient(issueId, clientId) {
    return api.post(`/issues/${issueId}/clients`, { client_id: clientId })
  },

  unshareFromClient(issueId, clientId) {
    return api.delete(`/issues/${issueId}/clients/${clientId}`)
  },

  // People
  getPeople(issueId) {
    return api.get(`/issues/${issueId}/people`)
  },

  addPerson(issueId, personId) {
    return api.post(`/issues/${issueId}/people`, { person_id: personId })
  },

  removePerson(issueId, personId) {
    return api.delete(`/issues/${issueId}/people/${personId}`)
  },
}

export default issuesApi
