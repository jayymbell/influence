import { ref } from 'vue'
import { defineStore } from 'pinia'
import issuesApi from '../services/issues'

const useIssueStore = defineStore('IssueStore', () => {
  const issues = ref([])
  const currentIssue = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  const fetchIssues = async (params = {}) => {
    isLoading.value = true
    error.value = null
    try {
      const response = await issuesApi.getAll(params)
      issues.value = response.data.issues
    } catch (e) {
      error.value = e.response?.data?.errors || ['Failed to load issues.']
    } finally {
      isLoading.value = false
    }
  }

  const fetchIssue = async (id) => {
    isLoading.value = true
    error.value = null
    try {
      const response = await issuesApi.get(id)
      currentIssue.value = response.data.issue
    } catch (e) {
      error.value = e.response?.data?.errors || ['Failed to load issue.']
    } finally {
      isLoading.value = false
    }
  }

  const createIssue = async (data) => {
    const response = await issuesApi.create(data)
    issues.value.unshift(response.data.issue)
    return response.data.issue
  }

  const updateIssue = async (id, data) => {
    const response = await issuesApi.update(id, data)
    const updated = response.data.issue
    const idx = issues.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) issues.value[idx] = updated
    if (currentIssue.value?.id === updated.id) currentIssue.value = updated
    return updated
  }

  const closeIssue = async (id) => {
    const response = await issuesApi.close(id)
    const updated = response.data.issue
    const idx = issues.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) issues.value[idx] = updated
    if (currentIssue.value?.id === updated.id) currentIssue.value = updated
    return updated
  }

  const deactivateIssue = async (id) => {
    const response = await issuesApi.deactivate(id)
    const updated = response.data.issue
    const idx = issues.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) issues.value[idx] = updated
    if (currentIssue.value?.id === updated.id) currentIssue.value = updated
    return updated
  }

  const reactivateIssue = async (id) => {
    const response = await issuesApi.reactivate(id)
    const updated = response.data.issue
    const idx = issues.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) issues.value[idx] = updated
    if (currentIssue.value?.id === updated.id) currentIssue.value = updated
    return updated
  }

  const shareWithClient = async (issueId, clientId) => {
    const response = await issuesApi.shareWithClient(issueId, clientId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value.shared_clients = response.data.clients
    }
    return response.data.clients
  }

  const unshareFromClient = async (issueId, clientId) => {
    const response = await issuesApi.unshareFromClient(issueId, clientId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value.shared_clients = response.data.clients
    }
    return response.data.clients
  }

  const addPerson = async (issueId, personId) => {
    const response = await issuesApi.addPerson(issueId, personId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value.people = response.data.people
    }
    return response.data.people
  }

  const removePerson = async (issueId, personId) => {
    const response = await issuesApi.removePerson(issueId, personId)
    if (currentIssue.value?.id === issueId) {
      currentIssue.value.people = response.data.people
    }
    return response.data.people
  }

  return {
    issues,
    currentIssue,
    isLoading,
    error,
    fetchIssues,
    fetchIssue,
    createIssue,
    updateIssue,
    closeIssue,
    deactivateIssue,
    reactivateIssue,
    shareWithClient,
    unshareFromClient,
    addPerson,
    removePerson,
  }
})

export default useIssueStore
