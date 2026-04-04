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
          </v-col>
          <v-col cols="auto">
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
          <v-btn v-if="editTarget" color="error" variant="text" @click="openDeleteDialog">Delete</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="closeDialog">Cancel</v-btn>
          <v-btn color="primary" @click="editTarget ? updatePerson() : createPerson()">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete confirmation dialog -->
    <v-dialog v-model="deleteDialogOpen" max-width="420">
      <v-card>
        <v-card-title class="pt-5 px-6">Delete person?</v-card-title>
        <v-card-text class="px-6">
          <strong>{{ editTarget?.display_name }}</strong> will be permanently removed.
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="deleteDialogOpen = false">Cancel</v-btn>
          <v-btn color="error" @click="deletePerson">Delete</v-btn>
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
const editTarget = ref(null)
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
    showSnackbar(['Person deleted'], 'success')
    deleteDialogOpen.value = false
    closeDialog()
    fetchPeople(searchQuery.value)
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

onMounted(() => fetchPeople())
</script>
