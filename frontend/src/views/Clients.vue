<template>
  <v-container>
    <v-row align="center" class="mb-2">
      <v-col>
        <h1>Clients</h1>
      </v-col>
      <v-col class="text-right">
        <v-btn color="primary" @click="openCreateDialog">New Client</v-btn>
      </v-col>
    </v-row>

    <v-row align="center" class="mb-2">
      <v-col cols="8">
        <v-text-field
          v-model="searchQuery"
          label="Search by name"
          clearable
          @update:model-value="debouncedSearch"
          @click:clear="onClearSearch"
        />
      </v-col>
      <v-col>
        <v-switch
          v-model="showActive"
          :label="showActive ? 'Active' : 'Inactive'"
          @update:model-value="fetchClients(searchQuery)"
          hide-details
        />
      </v-col>
    </v-row>

    <!-- Loading skeletons -->
    <template v-if="loading">
      <v-skeleton-loader v-for="n in 4" :key="n" type="list-item-two-line" class="mb-2" />
    </template>

    <!-- List -->
    <template v-else>
      <v-card v-for="c in clients" :key="c.id" class="pa-3 mt-2" outlined>
        <v-row align="center">
          <v-col>
            <strong>{{ c.display_name }}</strong>
            <span v-if="c.legal_name !== c.display_name" class="text-medium-emphasis"> — {{ c.legal_name }}</span>
            <v-chip v-if="c.status === 'inactive'" size="x-small" color="warning" variant="tonal" class="ml-2">Inactive</v-chip>
          </v-col>
          <v-col cols="auto">
            <v-btn variant="text" size="small" @click="openEditDialog(c)">Edit</v-btn>
          </v-col>
        </v-row>
      </v-card>

      <p v-if="!clients.length" class="text-medium-emphasis mt-4">No clients found.</p>
    </template>

    <!-- Create / Edit dialog -->
    <v-dialog v-model="dialogOpen" max-width="600" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">{{ editTarget ? 'Edit Client' : 'New Client' }}</v-card-title>
        <v-card-text class="px-6">
          <v-row>
            <v-col cols="12">
              <v-text-field
                v-model="form.legal_name"
                label="Legal Name *"
                @update:model-value="!editTarget && debouncedSimilarSearch($event)"
              />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.display_name" label="Display Name *" />
            </v-col>
          </v-row>
          <div v-if="!editTarget && similarSuggestions.length" class="mb-2">
            <p class="text-body-2 text-warning mb-2">
              Similar clients already exist — are you sure you want to create a new one?
            </p>
            <v-chip
              v-for="c in similarSuggestions"
              :key="c.id"
              class="mr-1 mb-1"
              color="warning"
              variant="outlined"
            >
              {{ c.display_name }}
              <span v-if="c.legal_name !== c.display_name" class="text-medium-emphasis ml-1">({{ c.legal_name }})</span>
            </v-chip>
          </div>
          <p class="text-body-2 text-medium-emphasis mt-1">* Required</p>
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-btn v-if="editTarget && editTarget.status === 'inactive'" color="success" variant="text" @click="reactivateClient">Reactivate</v-btn>
          <v-btn v-if="editTarget && editTarget.status === 'active'" color="error" variant="text" @click="openDeleteDialog">Deactivate</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="closeDialog">Cancel</v-btn>
          <v-btn v-if="!editTarget && forceCreate" color="warning" @click="createClient(true)">Create Anyway</v-btn>
          <v-btn v-else color="primary" @click="editTarget ? updateClient() : createClient()">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Deactivate confirmation dialog -->
    <v-dialog v-model="deleteDialogOpen" max-width="420">
      <v-card>
        <v-card-title class="pt-5 px-6">Deactivate client?</v-card-title>
        <v-card-text class="px-6">
          <strong>{{ editTarget?.display_name }}</strong> will be deactivated. You can reactivate it later.
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="deleteDialogOpen = false">Cancel</v-btn>
          <v-btn color="error" @click="deleteClient">Deactivate</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject } from 'vue'
import { debounce } from 'lodash'
import api from '../services/api.js'
import { trackEvent } from '../services/ahoy.js'

const clients = ref([])
const loading = ref(false)
const searchQuery = ref('')
const showActive = ref(true)
const dialogOpen = ref(false)
const deleteDialogOpen = ref(false)
const editTarget = ref(null)
const similarSuggestions = ref([])
const forceCreate = ref(false)
const showSnackbar = inject('showSnackbar')

const blankForm = () => ({ legal_name: '', display_name: '' })
const form = ref(blankForm())

const hydrateForm = (c) => {
  form.value = {
    legal_name: c.legal_name || '',
    display_name: c.display_name || ''
  }
}

const fetchClients = async (query = '') => {
  loading.value = true
  try {
    const params = {}
    if (query) params.query = query
    if (!showActive.value) params.discarded = 'true'
    const response = await api.get('/clients', { params })
    clients.value = response.data.clients
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const debouncedSearch = debounce(() => fetchClients(searchQuery.value), 300)

const onClearSearch = () => {
  searchQuery.value = ''
  fetchClients()
}

const openCreateDialog = () => {
  editTarget.value = null
  form.value = blankForm()
  similarSuggestions.value = []
  forceCreate.value = false
  dialogOpen.value = true
}

const openEditDialog = async (c) => {
  try {
    const response = await api.get('/clients/' + c.id)
    editTarget.value = response.data.client
    hydrateForm(editTarget.value)
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
  similarSuggestions.value = []
  forceCreate.value = false
}

const openDeleteDialog = () => {
  deleteDialogOpen.value = true
}

const searchSimilar = async (query) => {
  if (!query || query.trim().length < 2) {
    similarSuggestions.value = []
    return
  }
  try {
    const response = await api.get('/clients/similar', { params: { query } })
    const q = query.trim().toLowerCase()
    similarSuggestions.value = (response.data.clients || []).filter(c =>
      c.display_name.toLowerCase() !== q && c.legal_name.toLowerCase() !== q
    )
  } catch {
    similarSuggestions.value = []
  }
}

const debouncedSimilarSearch = debounce((val) => {
  forceCreate.value = false
  searchSimilar(val)
}, 300)

const createClient = async (force = false) => {
  if (!force) {
    await searchSimilar(form.value.legal_name)
    if (similarSuggestions.value.length) {
      forceCreate.value = true
      return
    }
  }
  try {
    const response = await api.post('/clients', { client: form.value })
    trackEvent('created client', { client_id: response.data.client.id })
    showSnackbar(['Client created'], 'success')
    closeDialog()
    fetchClients(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const updateClient = async () => {
  try {
    await api.patch('/clients/' + editTarget.value.id, { client: form.value })
    trackEvent('updated client', { client_id: editTarget.value.id })
    showSnackbar(['Client updated'], 'success')
    closeDialog()
    fetchClients(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const deleteClient = async () => {
  try {
    await api.delete('/clients/' + editTarget.value.id)
    trackEvent('deactivated client', { client_id: editTarget.value.id })
    showSnackbar(['Client deactivated'], 'success')
    deleteDialogOpen.value = false
    closeDialog()
    fetchClients(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const reactivateClient = async () => {
  try {
    await api.post('/clients/' + editTarget.value.id + '/reactivate')
    trackEvent('reactivated client', { client_id: editTarget.value.id })
    showSnackbar(['Client reactivated'], 'success')
    closeDialog()
    fetchClients(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

onMounted(() => fetchClients())

defineExpose({
  clients, loading, searchQuery, showActive, dialogOpen, deleteDialogOpen,
  editTarget, form, fetchClients, debouncedSearch, onClearSearch,
  openCreateDialog, openEditDialog, closeDialog, openDeleteDialog,
  createClient, updateClient, deleteClient, reactivateClient,
  similarSuggestions, forceCreate, searchSimilar, debouncedSimilarSearch
})
</script>
