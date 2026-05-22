import api from './api'

const billsApi = {
  getAll(params = {}) {
    return api.get('/bills', { params })
  },

  get(id) {
    return api.get(`/bills/${id}`)
  },

  create(data) {
    return api.post('/bills', { bill: data })
  },

  update(id, data) {
    return api.patch(`/bills/${id}`, { bill: data })
  },

  destroy(id) {
    return api.delete(`/bills/${id}`)
  },

  // Issues (nested under bill)
  getIssues(billId) {
    return api.get(`/bills/${billId}/issues`)
  },

  linkIssue(billId, issueId) {
    return api.post(`/bills/${billId}/issues`, { issue_id: issueId })
  },

  unlinkIssue(billId, issueId) {
    return api.delete(`/bills/${billId}/issues/${issueId}`)
  },

  // Clients (nested under bill)
  getClients(billId) {
    return api.get(`/bills/${billId}/clients`)
  },

  linkClient(billId, clientId) {
    return api.post(`/bills/${billId}/clients`, { client_id: clientId })
  },

  unlinkClient(billId, clientId) {
    return api.delete(`/bills/${billId}/clients/${clientId}`)
  },

  // People (nested under bill)
  getPeople(billId) {
    return api.get(`/bills/${billId}/people`)
  },

  addPerson(billId, personId) {
    return api.post(`/bills/${billId}/people`, { person_id: personId })
  },

  removePerson(billId, personId) {
    return api.delete(`/bills/${billId}/people/${personId}`)
  },

  // Bills nested under issue
  getIssueBills(issueId) {
    return api.get(`/issues/${issueId}/bills`)
  },

  linkBillToIssue(issueId, billId) {
    return api.post(`/issues/${issueId}/bills`, { bill_id: billId })
  },

  unlinkBillFromIssue(issueId, billId) {
    return api.delete(`/issues/${issueId}/bills/${billId}`)
  },
}

export default billsApi
