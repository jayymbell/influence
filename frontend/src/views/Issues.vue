<template>
  <v-container>
    <v-row align="center" class="mb-2">
      <v-col>
        <h1>Issues</h1>
      </v-col>
      <v-col class="text-right">
        <v-btn color="primary" @click="openCreateDialog">New Issue</v-btn>
      </v-col>
    </v-row>

    <!-- Filters -->
    <v-row align="center" class="mb-2">
      <v-col cols="6">
        <v-text-field
          v-model="searchQuery"
          label="Search by title"
          clearable
          @update:model-value="debouncedSearch"
          @click:clear="onClearSearch"
        />
      </v-col>
      <v-col cols="3">
        <v-select
          v-model="statusFilter"
          :items="statusOptions"
          label="Status"
          clearable
          @update:model-value="fetchIssues"
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
        v-for="issue in issues"
        :key="issue.id"
        class="pa-3 mt-2"
        outlined
      >
        <v-row align="center">
          <v-col>
            <strong>{{ issue.title }}</strong>
            <span v-if="issue.client" class="text-medium-emphasis ml-2 text-body-2">{{ issue.client.display_name }}</span>
            <div class="mt-1">
              <v-chip
                size="x-small"
                :color="statusColor(issue.status)"
                variant="tonal"
                class="mr-1"
              >{{ issue.status }}</v-chip>
              <v-chip
                v-for="tag in issue.tags"
                :key="tag"
                size="x-small"
                variant="outlined"
                class="mr-1"
              >{{ tag }}</v-chip>
            </div>
          </v-col>
          <v-col cols="auto">
            <v-btn variant="text" size="small" :to="{ name: 'IssueShow', params: { id: issue.id } }">View</v-btn>
            <v-btn variant="text" size="small" @click="openEditDialog(issue)">Edit</v-btn>
          </v-col>
        </v-row>
      </v-card>

      <p v-if="!issues.length" class="text-medium-emphasis mt-4">No issues found.</p>
    </template>

    <!-- Create / Edit dialog -->
    <v-dialog v-model="dialogOpen" max-width="640" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">{{ editTarget ? 'Edit Issue' : 'New Issue' }}</v-card-title>
        <v-card-text class="px-6">
          <v-row>
            <v-col cols="12">
              <v-text-field v-model="form.title" label="Title *" />
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
            <v-col v-if="!editTarget" cols="12">
              <v-select
                v-model="form.client_id"
                :items="clientOptions"
                item-title="display_name"
                item-value="id"
                label="Client *"
              />
            </v-col>
          </v-row>
          <p class="text-body-2 text-medium-emphasis mt-1">* Required</p>
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="closeDialog">Cancel</v-btn>
          <v-btn color="primary" @click="editTarget ? updateIssue() : createIssue()">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject } from 'vue'
import { debounce } from 'lodash'
import issuesApi from '../services/issues.js'
import api from '../services/api.js'

const issues = ref([])
const loading = ref(false)
const searchQuery = ref('')
const statusFilter = ref(null)
const dialogOpen = ref(false)
const editTarget = ref(null)
const clientOptions = ref([])
const showSnackbar = inject('showSnackbar')

const statusOptions = ['active', 'inactive', 'closed']

const blankForm = () => ({ title: '', description: '', notes: '', tags: [], client_id: null })
const form = ref(blankForm())

const statusColor = (status) => {
  if (status === 'active')   return 'success'
  if (status === 'inactive') return 'warning'
  if (status === 'closed')   return 'default'
  return 'default'
}

const fetchIssues = async () => {
  loading.value = true
  try {
    const params = {}
    if (searchQuery.value) params.query = searchQuery.value
    if (statusFilter.value)  params.status = statusFilter.value
    const response = await issuesApi.getAll(params)
    issues.value = response.data.issues
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const debouncedSearch = debounce(() => fetchIssues(), 300)

const onClearSearch = () => {
  searchQuery.value = ''
  fetchIssues()
}

const fetchClients = async () => {
  try {
    const response = await api.get('/clients')
    clientOptions.value = response.data.clients
  } catch (_) {
    // silently ignore — client picker just won't populate
  }
}

const openCreateDialog = () => {
  editTarget.value = null
  form.value = blankForm()
  fetchClients()
  dialogOpen.value = true
}

const openEditDialog = async (issue) => {
  try {
    const response = await issuesApi.get(issue.id)
    editTarget.value = response.data.issue
    form.value = {
      title:       editTarget.value.title || '',
      description: editTarget.value.description || '',
      notes:       editTarget.value.notes || '',
      tags:        editTarget.value.tags || [],
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

const createIssue = async () => {
  try {
    const response = await issuesApi.create(form.value)
    issues.value.unshift(response.data.issue)
    closeDialog()
    showSnackbar(['Issue created.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const updateIssue = async () => {
  try {
    const response = await issuesApi.update(editTarget.value.id, form.value)
    const updated = response.data.issue
    const idx = issues.value.findIndex((i) => i.id === updated.id)
    if (idx !== -1) issues.value[idx] = updated
    closeDialog()
    showSnackbar(['Issue updated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

onMounted(fetchIssues)

defineExpose({
  issues, loading, searchQuery, statusFilter, dialogOpen, editTarget,
  clientOptions, form, fetchIssues, debouncedSearch, onClearSearch,
  openCreateDialog, openEditDialog, closeDialog, createIssue, updateIssue,
  statusColor
})
</script>
