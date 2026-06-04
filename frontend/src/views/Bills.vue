<template>
  <v-container>
    <v-row align="center" class="mb-2">
      <v-col>
        <h1>Bills</h1>
      </v-col>
      <v-col class="text-right">
        <v-btn variant="outlined" class="mr-2" @click="searchModalOpen = true">Search Open States</v-btn>
        <v-btn color="primary" @click="openCreateDialog">New Bill</v-btn>
      </v-col>
    </v-row>

    <!-- Filters -->
    <v-row align="center" class="mb-2">
      <v-col cols="5">
        <v-text-field
          v-model="searchQuery"
          label="Search by title or bill number"
          clearable
          @update:model-value="debouncedSearch"
          @click:clear="onClearSearch"
        />
      </v-col>
      <v-col cols="2">
        <v-select
          v-model="statusFilter"
          :items="statusOptions"
          label="Status"
          clearable
          @update:model-value="fetchBills"
        />
      </v-col>
      <v-col cols="2">
        <v-select
          v-model="chamberFilter"
          :items="chamberOptions"
          label="Chamber"
          clearable
          @update:model-value="fetchBills"
        />
      </v-col>
      <v-col cols="2">
        <v-text-field
          v-model="sessionYearFilter"
          label="Session Year"
          type="number"
          clearable
          @update:model-value="debouncedSearch"
          @click:clear="onClearSearch"
        />
      </v-col>
    </v-row>

    <!-- Loading -->
    <template v-if="loading">
      <v-skeleton-loader v-for="n in 4" :key="n" type="list-item-two-line" class="mb-2" />
    </template>

    <!-- List -->
    <template v-else>
      <v-card
        v-for="bill in bills"
        :key="bill.id"
        class="pa-3 mt-2"
        outlined
      >
        <v-row align="center">
          <v-col>
            <span v-if="bill.bill_number" class="text-high-emphasis font-weight-bold mr-2">{{ bill.bill_number }}</span><span class="text-medium-emphasis">{{ bill.title }}</span>
            <div class="mt-1">
              <v-chip
                size="x-small"
                :color="statusColor(bill.status)"
                variant="tonal"
                class="mr-1"
              >{{ formatStatus(bill.status) }}</v-chip>
              <v-chip
                v-if="bill.chamber"
                size="x-small"
                :color="chamberColor(bill.chamber)"
                variant="tonal"
                class="mr-1"
              >{{ bill.chamber }}</v-chip>
              <v-chip
                v-if="bill.session_year"
                size="x-small"
                variant="outlined"
                class="mr-1"
              >{{ bill.session_year }}</v-chip>
              <v-chip
                v-for="tag in bill.tags"
                :key="tag"
                size="x-small"
                variant="outlined"
                class="mr-1"
              >{{ tag }}</v-chip>
            </div>
          </v-col>
          <v-col cols="auto">
            <v-btn variant="text" size="small" :to="{ name: 'BillShow', params: { id: bill.id } }">View</v-btn>
            <v-btn variant="text" size="small" @click="openEditDialog(bill)">Edit</v-btn>
          </v-col>
        </v-row>
      </v-card>

      <p v-if="!bills.length" class="text-medium-emphasis mt-4">No bills found.</p>
    </template>

    <!-- Create / Edit dialog -->
    <v-dialog v-model="dialogOpen" max-width="680" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">{{ editTarget ? 'Edit Bill' : 'New Bill' }}</v-card-title>
        <v-card-text class="px-6">
          <v-row>
            <v-col cols="12">
              <v-text-field v-model="form.title" label="Title *" />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model="form.bill_number" label="Bill Number (e.g. HF 1234)" />
            </v-col>
            <v-col cols="3">
              <v-select v-model="form.chamber" :items="chamberOptions" label="Chamber" clearable />
            </v-col>
            <v-col cols="3">
              <v-text-field v-model="form.session_year" label="Session Year" type="number" />
            </v-col>
            <v-col cols="12">
              <v-select v-model="form.status" :items="statusSelectOptions" label="Status" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description" rows="3" auto-grow />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.notes" label="Notes" rows="2" auto-grow />
            </v-col>
            <v-col cols="12">
              <v-combobox
                v-model="form.tags"
                label="Tags"
                multiple
                chips
                closable-chips
                hint="Type a tag and press Enter"
              />
            </v-col>
          </v-row>
          <p class="text-body-2 text-medium-emphasis mt-1">* Required</p>
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="closeDialog">Cancel</v-btn>
          <v-btn color="primary" @click="editTarget ? updateBill() : createBill()">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Open States import modal -->
    <BillSearchModal v-model="searchModalOpen" mode="import" />
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject } from 'vue'
import { debounce } from 'lodash'
import billsApi from '../services/bills.js'
import BillSearchModal from '../components/BillSearchModal.vue'

const bills = ref([])
const loading = ref(false)
const searchModalOpen = ref(false)
const searchQuery = ref('')
const statusFilter = ref(null)
const chamberFilter = ref(null)
const sessionYearFilter = ref(null)
const dialogOpen = ref(false)
const editTarget = ref(null)
const showSnackbar = inject('showSnackbar')

const statusOptions = [
  'introduced', 'in_committee', 'passed_committee', 'floor_vote',
  'passed_chamber', 'passed_both_chambers', 'signed', 'vetoed', 'failed', 'carried_over',
]
const statusSelectOptions = statusOptions.map((s) => ({ title: formatStatus(s), value: s }))
const chamberOptions = ['house', 'senate']

function formatStatus(s) {
  return s ? s.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()) : ''
}

const statusColor = (status) => {
  const map = {
    introduced: 'blue', in_committee: 'indigo', passed_committee: 'cyan',
    floor_vote: 'orange', passed_chamber: 'teal', passed_both_chambers: 'green',
    signed: 'success', vetoed: 'error', failed: 'default', carried_over: 'warning',
  }
  return map[status] || 'default'
}

const chamberColor = (chamber) => chamber === 'house' ? 'blue-grey' : 'purple'

const blankForm = () => ({
  title: '', bill_number: '', chamber: null, session_year: null,
  status: 'introduced', description: '', notes: '', tags: [],
})
const form = ref(blankForm())

const fetchBills = async () => {
  loading.value = true
  try {
    const params = {}
    if (searchQuery.value)      params.query = searchQuery.value
    if (statusFilter.value)     params.status = statusFilter.value
    if (chamberFilter.value)    params.chamber = chamberFilter.value
    if (sessionYearFilter.value) params.session_year = sessionYearFilter.value
    const response = await billsApi.getAll(params)
    bills.value = response.data.bills
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const debouncedSearch = debounce(() => fetchBills(), 300)

const onClearSearch = () => {
  searchQuery.value = ''
  sessionYearFilter.value = null
  fetchBills()
}

const openCreateDialog = () => {
  editTarget.value = null
  form.value = blankForm()
  dialogOpen.value = true
}

const openEditDialog = async (bill) => {
  try {
    const response = await billsApi.get(bill.id)
    editTarget.value = response.data.bill
    form.value = {
      title:        editTarget.value.title || '',
      bill_number:  editTarget.value.bill_number || '',
      chamber:      editTarget.value.chamber || null,
      session_year: editTarget.value.session_year || null,
      status:       editTarget.value.status || 'introduced',
      description:  editTarget.value.description || '',
      notes:        editTarget.value.notes || '',
      tags:         editTarget.value.tags || [],
    }
    dialogOpen.value = true
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const closeDialog = () => {
  dialogOpen.value = false
  editTarget.value = null
  form.value = blankForm()
}

const createBill = async () => {
  try {
    const response = await billsApi.create(form.value)
    bills.value.unshift(response.data.bill)
    closeDialog()
    showSnackbar(['Bill created.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const updateBill = async () => {
  try {
    const response = await billsApi.update(editTarget.value.id, form.value)
    const updated = response.data.bill
    const idx = bills.value.findIndex((b) => b.id === updated.id)
    if (idx !== -1) bills.value[idx] = updated
    closeDialog()
    showSnackbar(['Bill updated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

onMounted(fetchBills)

defineExpose({
  bills, loading, searchQuery, statusFilter, chamberFilter, sessionYearFilter,
  dialogOpen, editTarget, form, searchModalOpen, fetchBills, debouncedSearch, onClearSearch,
  openCreateDialog, openEditDialog, closeDialog, createBill, updateBill,
  statusColor, chamberColor, formatStatus,
})
</script>
