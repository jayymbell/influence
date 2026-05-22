<template>
  <v-container>
    <v-btn variant="text" :to="{ name: 'Issues' }" class="mb-4 pl-0">&larr; Issues</v-btn>

    <!-- Loading -->
    <template v-if="loading">
      <v-skeleton-loader type="article" />
    </template>

    <!-- Issue detail -->
    <template v-else-if="issue">
      <v-row align="center" class="mb-1">
        <v-col>
          <h1>
            {{ issue.title }}
            <v-chip
              size="small"
              :color="statusColor(issue.status)"
              variant="tonal"
              class="ml-2"
            >{{ issue.status }}</v-chip>
          </h1>
          <div v-if="issue.tags?.length" class="mt-1">
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
          <!-- Status actions -->
          <v-btn
            v-if="issue.status === 'active'"
            variant="outlined"
            size="small"
            color="warning"
            class="mr-2"
            @click="deactivate"
          >Deactivate</v-btn>
          <v-btn
            v-if="issue.status === 'active'"
            variant="outlined"
            size="small"
            color="error"
            class="mr-2"
            @click="confirmClose = true"
          >Close</v-btn>
          <v-btn
            v-if="issue.status !== 'active'"
            variant="outlined"
            size="small"
            color="success"
            class="mr-2"
            @click="reactivate"
          >Reactivate</v-btn>
          <v-btn variant="outlined" size="small" @click="openEditDialog">Edit</v-btn>
        </v-col>
      </v-row>

      <!-- Description / Notes -->
      <v-row v-if="issue.description || issue.notes" class="mt-2">
        <v-col v-if="issue.description" cols="12" md="6">
          <p class="text-body-2 text-medium-emphasis mb-1">Description</p>
          <p class="text-body-1">{{ issue.description }}</p>
        </v-col>
        <v-col v-if="issue.notes" cols="12" md="6">
          <p class="text-body-2 text-medium-emphasis mb-1">Notes</p>
          <p class="text-body-1">{{ issue.notes }}</p>
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-tabs v-model="activeTab" class="mt-4">
        <v-tab value="people">People</v-tab>
        <v-tab value="clients">Clients</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="activeTab" class="mt-4">
        <!-- People tab -->
        <v-window-item value="people">
          <v-row align="center" class="mb-2">
            <v-col cols="8">
              <v-autocomplete
                v-model="selectedPerson"
                :items="availablePeopleOptions"
                label="Add person"
                clearable
                no-data-text="No people found"
                item-props
              />
            </v-col>
            <v-col cols="auto">
              <v-btn color="primary" :disabled="!selectedPerson" @click="addPerson">Add</v-btn>
            </v-col>
          </v-row>

          <template v-if="peopleLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>
          <template v-else>
            <v-table v-if="issue.people?.length" hover>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Title</th>
                  <th>Organization</th>
                  <th>Email</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in issue.people" :key="p.id">
                  <td>{{ p.display_name }}</td>
                  <td>{{ p.title || '—' }}</td>
                  <td>{{ p.organization_name || '—' }}</td>
                  <td>{{ p.email || '—' }}</td>
                  <td class="text-right">
                    <v-btn variant="text" size="small" color="error" @click="removePerson(p.id)">Remove</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>
            <p v-else class="text-medium-emphasis mt-4">No people assigned to this issue.</p>
          </template>
        </v-window-item>

        <!-- Shared Clients tab -->
        <v-window-item value="clients">
          <v-row v-if="canShare" align="center" class="mb-2">
            <v-col cols="8">
              <v-autocomplete
                v-model="selectedShareClient"
                :items="availableShareClientOptions"
                label="Share with client"
                clearable
                no-data-text="No clients available"
              />
            </v-col>
            <v-col cols="auto">
              <v-btn color="primary" :disabled="!selectedShareClient" @click="shareWithClient">Share</v-btn>
            </v-col>
          </v-row>

          <template v-if="clientsLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>
          <template v-else>
            <v-table hover>
              <thead>
                <tr>
                  <th>Client</th>
                  <th>Shared</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="issue.client">
                  <td>
                    {{ issue.client.display_name }}
                    <v-chip size="x-small" color="primary" variant="tonal" class="ml-1">primary</v-chip>
                  </td>
                  <td>—</td>
                  <td></td>
                </tr>
                <tr v-for="c in issue.shared_clients" :key="c.id">
                  <td>{{ c.display_name }}</td>
                  <td>{{ c.shared_at ? new Date(c.shared_at).toLocaleDateString() : '—' }}</td>
                  <td class="text-right">
                    <v-btn
                      v-if="canShare"
                      variant="text"
                      size="small"
                      color="error"
                      @click="unshareFromClient(c.id)"
                    >Unshare</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>
          </template>
        </v-window-item>
      </v-window>
    </template>

    <template v-else>
      <p class="text-medium-emphasis">Issue not found.</p>
    </template>

    <!-- Close confirmation dialog -->
    <v-dialog v-model="confirmClose" max-width="420">
      <v-card>
        <v-card-title class="pt-5 px-6">Close issue?</v-card-title>
        <v-card-text class="px-6">
          <strong>{{ issue?.title }}</strong> will be marked as closed. You can reactivate it later.
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="confirmClose = false">Cancel</v-btn>
          <v-btn color="error" @click="closeIssue">Close Issue</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Edit dialog -->
    <v-dialog v-model="editDialogOpen" max-width="640" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">Edit Issue</v-card-title>
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
          </v-row>
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="editDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" @click="saveEdit">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject, computed } from 'vue'
import { useRoute } from 'vue-router'
import issuesApi from '../services/issues.js'
import api from '../services/api.js'
import useUserStore from '../stores/UserStore.js'

const route = useRoute()
const showSnackbar = inject('showSnackbar')
const userStore = useUserStore()

const canShare = userStore.hasRole('admin') || userStore.hasRole('manager')

const issue = ref(null)
const loading = ref(false)
const peopleLoading = ref(false)
const clientsLoading = ref(false)
const activeTab = ref('people')
const confirmClose = ref(false)
const editDialogOpen = ref(false)
const selectedPerson = ref(null)
const selectedShareClient = ref(null)
const availablePeopleOptions = ref([])
const availableShareClientOptions = ref([])

const form = ref({ title: '', description: '', notes: '', tags: [] })

const statusColor = (status) => {
  if (status === 'active')   return 'success'
  if (status === 'inactive') return 'warning'
  return 'default'
}

const fetchIssue = async () => {
  loading.value = true
  try {
    const response = await issuesApi.get(route.params.id)
    issue.value = response.data.issue
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const fetchAvailablePeople = async () => {
  try {
    const response = await api.get('/people')
    const assignedIds = (issue.value?.people || []).map((p) => p.id)
    availablePeopleOptions.value = (response.data.people || [])
      .filter((p) => !assignedIds.includes(p.id))
      .map((p) => ({
        title:    p.display_name,
        subtitle: [p.title, p.organization_name].filter(Boolean).join(' · ') || undefined,
        value:    p.id
      }))
  } catch (_) { /* silent */ }
}

const fetchAvailableShareClients = async () => {
  try {
    const response = await api.get('/clients')
    const linkedIds = (issue.value?.shared_clients || []).map((c) => c.id)
    const primaryId = issue.value?.client?.id
    availableShareClientOptions.value = (response.data.clients || [])
      .filter((c) => !linkedIds.includes(c.id) && c.id !== primaryId)
      .map((c) => ({ title: c.display_name, value: c.id }))
  } catch (_) { /* silent */ }
}

const openEditDialog = () => {
  form.value = {
    title:       issue.value.title || '',
    description: issue.value.description || '',
    notes:       issue.value.notes || '',
    tags:        issue.value.tags || [],
  }
  editDialogOpen.value = true
}

const saveEdit = async () => {
  try {
    const response = await issuesApi.update(issue.value.id, form.value)
    issue.value = response.data.issue
    editDialogOpen.value = false
    showSnackbar(['Issue updated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const deactivate = async () => {
  try {
    const response = await issuesApi.deactivate(issue.value.id)
    issue.value = response.data.issue
    showSnackbar(['Issue deactivated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const closeIssue = async () => {
  try {
    const response = await issuesApi.close(issue.value.id)
    issue.value = response.data.issue
    confirmClose.value = false
    showSnackbar(['Issue closed.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const reactivate = async () => {
  try {
    const response = await issuesApi.reactivate(issue.value.id)
    issue.value = response.data.issue
    showSnackbar(['Issue reactivated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const addPerson = async () => {
  peopleLoading.value = true
  try {
    const response = await issuesApi.addPerson(issue.value.id, selectedPerson.value)
    issue.value.people = response.data.people
    selectedPerson.value = null
    fetchAvailablePeople()
    showSnackbar(['Person added.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    peopleLoading.value = false
  }
}

const removePerson = async (personId) => {
  peopleLoading.value = true
  try {
    const response = await issuesApi.removePerson(issue.value.id, personId)
    issue.value.people = response.data.people
    fetchAvailablePeople()
    showSnackbar(['Person removed.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    peopleLoading.value = false
  }
}

const shareWithClient = async () => {
  clientsLoading.value = true
  try {
    const response = await issuesApi.shareWithClient(issue.value.id, selectedShareClient.value)
    issue.value.shared_clients = response.data.clients
    selectedShareClient.value = null
    fetchAvailableShareClients()
    showSnackbar(['Issue shared with client.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    clientsLoading.value = false
  }
}

const unshareFromClient = async (clientId) => {
  clientsLoading.value = true
  try {
    const response = await issuesApi.unshareFromClient(issue.value.id, clientId)
    issue.value.shared_clients = response.data.clients
    fetchAvailableShareClients()
    showSnackbar(['Issue unshared from client.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    clientsLoading.value = false
  }
}

onMounted(async () => {
  await fetchIssue()
  fetchAvailablePeople()
  if (canShare) fetchAvailableShareClients()
})

defineExpose({
  issue, loading, activeTab, confirmClose, editDialogOpen, form,
  fetchIssue, openEditDialog, saveEdit, deactivate, closeIssue, reactivate,
  addPerson, removePerson, shareWithClient, unshareFromClient,
  selectedPerson, selectedShareClient, canShare
})
</script>
