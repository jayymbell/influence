import { ref } from 'vue'
import { defineStore } from 'pinia'
import billsApi from '../services/bills'

const useBillStore = defineStore('BillStore', () => {
  const bills = ref([])
  const currentBill = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  const fetchBills = async (params = {}) => {
    isLoading.value = true
    error.value = null
    try {
      const response = await billsApi.getAll(params)
      bills.value = response.data.bills
    } catch (e) {
      error.value = e.response?.data?.errors || ['Failed to load bills.']
    } finally {
      isLoading.value = false
    }
  }

  const fetchBill = async (id) => {
    isLoading.value = true
    error.value = null
    try {
      const response = await billsApi.get(id)
      currentBill.value = response.data.bill
    } catch (e) {
      error.value = e.response?.data?.errors || ['Failed to load bill.']
    } finally {
      isLoading.value = false
    }
  }

  const createBill = async (data) => {
    const response = await billsApi.create(data)
    bills.value.unshift(response.data.bill)
    return response.data.bill
  }

  const updateBill = async (id, data) => {
    const response = await billsApi.update(id, data)
    const updated = response.data.bill
    const idx = bills.value.findIndex((b) => b.id === updated.id)
    if (idx !== -1) bills.value[idx] = updated
    if (currentBill.value?.id === updated.id) currentBill.value = updated
    return updated
  }

  const deleteBill = async (id) => {
    await billsApi.destroy(id)
    bills.value = bills.value.filter((b) => b.id !== id)
  }

  const linkIssue = async (billId, issueId) => {
    const response = await billsApi.linkIssue(billId, issueId)
    if (currentBill.value?.id === billId) {
      currentBill.value.issues = response.data.issues
    }
    return response.data.issues
  }

  const unlinkIssue = async (billId, issueId) => {
    const response = await billsApi.unlinkIssue(billId, issueId)
    if (currentBill.value?.id === billId) {
      currentBill.value.issues = response.data.issues
    }
    return response.data.issues
  }

  const linkClient = async (billId, clientId) => {
    const response = await billsApi.linkClient(billId, clientId)
    if (currentBill.value?.id === billId) {
      currentBill.value.clients = response.data.clients
    }
    return response.data.clients
  }

  const unlinkClient = async (billId, clientId) => {
    const response = await billsApi.unlinkClient(billId, clientId)
    if (currentBill.value?.id === billId) {
      currentBill.value.clients = response.data.clients
    }
    return response.data.clients
  }

  const addPerson = async (billId, personId) => {
    const response = await billsApi.addPerson(billId, personId)
    if (currentBill.value?.id === billId) {
      currentBill.value.people = response.data.people
    }
    return response.data.people
  }

  const removePerson = async (billId, personId) => {
    const response = await billsApi.removePerson(billId, personId)
    if (currentBill.value?.id === billId) {
      currentBill.value.people = response.data.people
    }
    return response.data.people
  }

  const fetchIssueBills = async (issueId) => {
    const response = await billsApi.getIssueBills(issueId)
    return response.data.bills
  }

  const linkBillToIssue = async (issueId, billId) => {
    const response = await billsApi.linkBillToIssue(issueId, billId)
    return response.data.bills
  }

  const unlinkBillFromIssue = async (issueId, billId) => {
    const response = await billsApi.unlinkBillFromIssue(issueId, billId)
    return response.data.bills
  }

  return {
    bills,
    currentBill,
    isLoading,
    error,
    fetchBills,
    fetchBill,
    createBill,
    updateBill,
    deleteBill,
    linkIssue,
    unlinkIssue,
    linkClient,
    unlinkClient,
    addPerson,
    removePerson,
    fetchIssueBills,
    linkBillToIssue,
    unlinkBillFromIssue,
  }
})

export default useBillStore
