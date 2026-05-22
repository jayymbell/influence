<template>
  <v-container>
    <v-row align="center" class="mb-2">
      <v-col>
        <h1>People</h1>
      </v-col>
      <v-col class="text-right">
        <v-btn color="primary" @click="openCreateDialog">New Person</v-btn>
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
          @update:model-value="fetchPeople(searchQuery)"
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
      <v-card v-for="p in people" :key="p.id" class="pa-3 mt-2" outlined>
        <v-row align="center">
          <v-col>
            <strong>{{ p.display_name }}</strong>
            <span v-if="p.title" class="text-medium-emphasis"> — {{ p.title }}</span>
            <span v-if="p.organization_name" class="text-medium-emphasis">, {{ p.organization_name }}</span>
            <div v-if="p.email" class="text-body-2 text-medium-emphasis">{{ p.email }}</div>
            <div class="mt-1">
              <v-chip
                v-if="p.client_id && !p.user_id"
                size="x-small"
                color="secondary"
                variant="outlined"
                class="mr-1"
              >client</v-chip>
              <v-chip
                v-for="role in (p.user && p.user.roles || [])"
                :key="role"
                size="x-small"
                :color="roleColor(role)"
                variant="tonal"
                class="mr-1"
              >{{ role }}</v-chip>
            </div>
          </v-col>
          <v-col cols="auto">
            <v-btn
              v-if="canAddAsClient(p)"
              variant="text" size="small" color="secondary"
              @click="openClientDialog(p)"
            >Client</v-btn>
            <v-btn
              v-if="p.user_id && !(p.user && p.user.roles && (p.user.roles.includes('staff') || p.user.roles.includes('client'))) && !p.discarded_at"
              variant="text" size="small" color="purple"
              @click="assignStaff(p)"
            >Staff</v-btn>
            <v-btn
              v-if="p.email && !p.user_id && !p.invitation_pending && !p.discarded_at"
              variant="text" size="small" color="primary"
              @click="invitePerson(p)"
            >Invite</v-btn>
            <v-btn
              v-if="p.invitation_pending && !p.discarded_at"
              variant="text" size="small" color="warning"
              @click="revokeInvitation(p)"
            >Revoke Invite</v-btn>
            <v-btn variant="text" size="small" @click="openEditDialog(p)">Edit</v-btn>
          </v-col>
        </v-row>
      </v-card>

      <p v-if="!people.length" class="text-medium-emphasis mt-4">No people found.</p>
    </template>

    <!-- Create / Edit dialog -->
    <v-dialog v-model="dialogOpen" max-width="700" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">{{ editTarget ? 'Edit Person' : 'New Person' }}</v-card-title>
        <v-card-text class="px-6">
          <PersonForm :form="form" />
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-btn v-if="editTarget && editTarget.discarded_at" color="success" variant="text" @click="reactivatePerson">Reactivate</v-btn>
          <v-btn v-if="editTarget && !editTarget.discarded_at" color="error" variant="text" @click="openDeleteDialog">Deactivate</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="closeDialog">Cancel</v-btn>
          <v-btn color="primary" @click="editTarget ? updatePerson() : createPerson()">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Add Client dialog -->
    <v-dialog v-model="clientDialogOpen" max-width="500" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">Add as Client Contact</v-card-title>
        <v-card-text class="px-6">
          <p class="text-body-2 text-medium-emphasis mb-4">
            Enter the client name. If a matching client already exists it will be used;
            otherwise a new client will be created.
          </p>
          <v-text-field
            v-model="clientForm.organization_name"
            label="Client / Organization Name *"
            autofocus
            @update:model-value="debouncedClientSearch"
          />
          <div v-if="clientSuggestions.length" class="mb-2">
            <p class="text-body-2 text-warning mb-2">
              Similar clients already exist — select one to avoid duplicates:
            </p>
            <v-chip
              v-for="c in clientSuggestions"
              :key="c.id"
              class="mr-1 mb-1"
              color="warning"
              variant="outlined"
              clickable
              @click="selectClientSuggestion(c)"
            >
              {{ c.display_name }}
              <span v-if="c.legal_name !== c.display_name" class="text-medium-emphasis ml-1">({{ c.legal_name }})</span>
            </v-chip>
          </div>
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="clientDialogOpen = false">Cancel</v-btn>
          <v-btn v-if="forceCreate" color="warning" @click="addClient">Create New Anyway</v-btn>
          <v-btn v-else-if="selectedExistingClient" color="primary" @click="addClient">Add to Existing Client</v-btn>
          <v-btn v-else color="primary" @click="addClient">Confirm</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete confirmation dialog -->
    <v-dialog v-model="deleteDialogOpen" max-width="420">
      <v-card>
        <v-card-title class="pt-5 px-6">Deactivate person?</v-card-title>
        <v-card-text class="px-6">
          <strong>{{ editTarget?.display_name }}</strong> will be deactivated.
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="deleteDialogOpen = false">Cancel</v-btn>
          <v-btn color="error" @click="deletePerson">Deactivate</v-btn>
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
import PersonForm from '../components/PersonForm.vue'

const people = ref([])
const loading = ref(false)
const searchQuery = ref('')
const showActive = ref(true)
const dialogOpen = ref(false)
const deleteDialogOpen = ref(false)
const clientDialogOpen = ref(false)
const editTarget = ref(null)
const clientTarget = ref(null)
const clientForm = ref({ organization_name: '' })
const clientSuggestions = ref([])
const forceCreate = ref(false)
const selectedExistingClient = ref(false)
const showSnackbar = inject('showSnackbar')

const blankForm = () => ({
  first_name: '',
  last_name: '',
  display_name: '',
  email: '',
  phone: '',
  title: '',
  organization_name: '',
  notes: ''
})

const form = ref(blankForm())

const hydrateForm = (p) => {
  form.value = {
    first_name: p.first_name || '',
    last_name: p.last_name || '',
    display_name: p.display_name || '',
    email: p.email || '',
    phone: p.phone || '',
    title: p.title || '',
    organization_name: p.organization_name || '',
    notes: p.notes || ''
  }
}

const fetchPeople = async (query = '') => {
  loading.value = true
  try {
    const params = {}
    if (query) params.query = query
    if (!showActive.value) params.discarded = 'true'
    const response = await api.get('/people', { params })
    people.value = response.data.people
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const debouncedSearch = debounce(() => fetchPeople(searchQuery.value), 300)

const onClearSearch = () => {
  searchQuery.value = ''
  fetchPeople()
}

const openCreateDialog = () => {
  editTarget.value = null
  form.value = blankForm()
  dialogOpen.value = true
}

const openEditDialog = async (p) => {
  try {
    const response = await api.get('/people/' + p.id)
    editTarget.value = response.data.person
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
}

const openDeleteDialog = () => {
  deleteDialogOpen.value = true
}

const createPerson = async () => {
  try {
    const response = await api.post('/people', { person: form.value })
    trackEvent('created person', { person_id: response.data.person.id })
    showSnackbar(['Person created'], 'success')
    closeDialog()
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const updatePerson = async () => {
  try {
    await api.patch('/people/' + editTarget.value.id, { person: form.value })
    trackEvent('updated person', { person_id: editTarget.value.id })
    showSnackbar(['Person updated'], 'success')
    closeDialog()
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const deletePerson = async () => {
  try {
    await api.delete('/people/' + editTarget.value.id)
    trackEvent('deleted person', { person_id: editTarget.value.id })
    showSnackbar(['Person deactivated'], 'success')
    deleteDialogOpen.value = false
    closeDialog()
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const reactivatePerson = async () => {
  try {
    await api.post('/people/' + editTarget.value.id + '/reactivate')
    trackEvent('reactivated person', { person_id: editTarget.value.id })
    showSnackbar(['Person reactivated'], 'success')
    closeDialog()
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const invitePerson = async (p) => {
  try {
    await api.post(`/people/${p.id}/invite`)
    trackEvent('invited person', { person_id: p.id })
    showSnackbar(['Invitation sent'], 'success')
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const revokeInvitation = async (p) => {
  try {
    await api.delete(`/people/${p.id}/invitation`)
    trackEvent('revoked invitation', { person_id: p.id })
    showSnackbar(['Invitation revoked'], 'success')
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const roleColor = (role) => {
  const colors = { admin: 'error', staff: 'purple', client: 'secondary' }
  return colors[role] || 'secondary'
}

const canAddAsClient = (p) => {
  if (p.discarded_at || p.client_id != null) return false
  if (!p.user_id) return true
  if (p.user && (!p.user.roles || p.user.roles.length === 0)) return true
  return false
}

const searchClientSuggestions = async (query) => {
  if (!query || query.trim().length < 2) {
    clientSuggestions.value = []
    return
  }
  try {
    const response = await api.get('/clients/similar', { params: { query } })
    const q = query.trim().toLowerCase()
    clientSuggestions.value = (response.data.clients || []).filter(c =>
      c.display_name.toLowerCase() !== q && c.legal_name.toLowerCase() !== q
    )
  } catch {
    clientSuggestions.value = []
  }
}

const debouncedClientSearch = debounce((val) => {
  forceCreate.value = false
  selectedExistingClient.value = false
  searchClientSuggestions(val)
}, 300)

const selectClientSuggestion = (c) => {
  clientForm.value.organization_name = c.display_name
  clientSuggestions.value = []
  forceCreate.value = false
  selectedExistingClient.value = true
}

const openClientDialog = (p) => {
  clientTarget.value = p
  clientForm.value = { organization_name: p.organization_name || '' }
  clientSuggestions.value = []
  forceCreate.value = false
  selectedExistingClient.value = false
  clientDialogOpen.value = true
}

const addClient = async () => {
  // Always re-check at submit time in case debounce hasn't fired yet
  if (!forceCreate.value) {
    await searchClientSuggestions(clientForm.value.organization_name)
    if (clientSuggestions.value.length) {
      forceCreate.value = true
      return
    }
  }
  try {
    const response = await api.post(`/people/${clientTarget.value.id}/add_client`, clientForm.value)
    trackEvent('added client', { person_id: clientTarget.value.id })
    showSnackbar([response.data.message || 'Person added as client contact'], 'success')
    clientDialogOpen.value = false
    clientTarget.value = null
    clientSuggestions.value = []
    forceCreate.value = false
    selectedExistingClient.value = false
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const assignStaff = async (p) => {
  try {
    await api.post(`/people/${p.id}/assign_staff`)
    trackEvent('assigned staff role', { person_id: p.id })
    showSnackbar(['Staff role assigned'], 'success')
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

onMounted(() => fetchPeople())

defineExpose({
  people,
  loading,
  searchQuery,
  showActive,
  dialogOpen,
  deleteDialogOpen,
  editTarget,
  form,
  fetchPeople,
  debouncedSearch,
  onClearSearch,
  openCreateDialog,
  openEditDialog,
  closeDialog,
  openDeleteDialog,
  createPerson,
  updatePerson,
  deletePerson,
  reactivatePerson,
  invitePerson,
  revokeInvitation,
  canAddAsClient,
  openClientDialog,
  clientDialogOpen,
  clientTarget,
  clientForm,
  addClient,
  assignStaff,
  clientSuggestions,
  forceCreate,
  selectedExistingClient,
  searchClientSuggestions,
  debouncedClientSearch,
  selectClientSuggestion
})
</script>
