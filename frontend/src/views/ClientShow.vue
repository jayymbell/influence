<template>
  <v-container>
    <v-btn variant="text" :to="{ name: 'Clients' }" class="mb-4 pl-0">&larr; Clients</v-btn>

    <!-- Loading state -->
    <template v-if="loading">
      <v-skeleton-loader type="article" />
    </template>

    <!-- Client info -->
    <template v-else-if="client">
      <v-row align="center" class="mb-1">
        <v-col>
          <h1>
            {{ client.display_name }}
            <v-chip
              v-if="client.status === 'inactive'"
              size="small"
              color="warning"
              variant="tonal"
              class="ml-2"
            >Inactive</v-chip>
          </h1>
          <p v-if="client.legal_name !== client.display_name" class="text-medium-emphasis mb-0">
            {{ client.legal_name }}
          </p>
        </v-col>
      </v-row>

      <!-- Tab menu -->
      <v-tabs v-model="activeTab" class="mt-4">
        <v-tab value="contacts">Contacts</v-tab>
        <v-tab value="staff">Staff</v-tab>
        <v-tab value="issues">Issues</v-tab>
      </v-tabs>

      <v-divider />

      <v-window v-model="activeTab" class="mt-4">
        <!-- Contacts tab -->
        <v-window-item value="contacts">
          <template v-if="peopleLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>

          <template v-else>
            <v-table v-if="people.length" hover>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Title</th>
                  <th>Email</th>
                  <th>Phone</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in people" :key="p.id">
                  <td>{{ p.display_name }}</td>
                  <td>{{ p.title || '—' }}</td>
                  <td>{{ p.email || '—' }}</td>
                  <td>{{ p.phone || '—' }}</td>
                </tr>
              </tbody>
            </v-table>

            <p v-else class="text-medium-emphasis mt-4">No contacts found for this client.</p>
          </template>
        </v-window-item>

        <!-- Staff tab -->
        <v-window-item value="staff">
          <v-row v-if="canManageStaff" align="center" class="mb-2">
            <v-col cols="8">
              <v-autocomplete
                v-model="selectedStaff"
                :items="availableStaffOptions"
                label="Select staff member"
                clearable
                no-data-text="No staff found"
              />
            </v-col>
            <v-col cols="auto">
              <v-btn
                color="primary"
                :disabled="!selectedStaff"
                @click="addStaff"
              >Add</v-btn>
            </v-col>
          </v-row>

          <template v-if="staffLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>

          <template v-else>
            <v-table v-if="staff.length" hover>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="s in staff" :key="s.id">
                  <td>{{ s.display_name || '—' }}</td>
                  <td>{{ s.email }}</td>
                  <td class="text-right">
                    <v-btn v-if="canManageStaff" variant="text" size="small" color="error" @click="removeStaff(s.id)">Remove</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>

            <p v-else class="text-medium-emphasis mt-4">No staff assigned to this client.</p>
          </template>
        </v-window-item>

        <!-- Issues tab -->
        <v-window-item value="issues">
          <template v-if="issuesLoading">
            <v-skeleton-loader v-for="n in 4" :key="n" type="list-item" class="mb-2" />
          </template>
          <template v-else>
            <v-table v-if="clientIssues.length" hover>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Status</th>
                  <th>Primary Client</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="issue in clientIssues" :key="issue.id">
                  <td>{{ issue.title }}</td>
                  <td>
                    <v-chip size="x-small" :color="issueStatusColor(issue.status)" variant="tonal">{{ issue.status }}</v-chip>
                  </td>
                  <td>{{ issue.client?.display_name || '—' }}</td>
                  <td class="text-right">
                    <v-btn variant="text" size="small" :to="{ name: 'IssueShow', params: { id: issue.id } }">View</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>
            <p v-else class="text-medium-emphasis mt-4">No issues found for this client.</p>
          </template>
        </v-window-item>
      </v-window>
    </template>
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import api from '../services/api.js'
import issuesApi from '../services/issues.js'
import useUserStore from '../stores/UserStore.js'

const route = useRoute()
const showSnackbar = inject('showSnackbar')
const userStore = useUserStore()
const canManageStaff = userStore.hasRole('admin') || userStore.hasRole('manager')

const client = ref(null)
const loading = ref(false)
const people = ref([])
const peopleLoading = ref(false)
const staff = ref([])
const staffLoading = ref(false)
const availableStaffOptions = ref([])
const selectedStaff = ref(null)

const activeTab = ref('contacts')
const clientIssues = ref([])
const issuesLoading = ref(false)

const fetchClient = async () => {
  loading.value = true
  try {
    const response = await api.get('/clients/' + route.params.id)
    client.value = response.data.client
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const fetchPeople = async () => {
  peopleLoading.value = true
  try {
    const response = await api.get('/people', { params: { client_id: route.params.id } })
    people.value = response.data.people
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    peopleLoading.value = false
  }
}

const fetchStaff = async () => {
  staffLoading.value = true
  try {
    const response = await api.get('/clients/' + route.params.id + '/staff')
    staff.value = response.data.staff
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    staffLoading.value = false
  }
}

const fetchAvailableStaff = async () => {
  try {
    const response = await api.get('/clients/' + route.params.id + '/staff/available')
    availableStaffOptions.value = (response.data.users || []).map(u => ({
      title: u.display_name ? `${u.display_name} (${u.email})` : u.email,
      value: u.id
    }))
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const addStaff = async () => {
  try {
    const response = await api.post('/clients/' + route.params.id + '/staff', { user_id: selectedStaff.value })
    staff.value = response.data.staff
    selectedStaff.value = null
    if (canManageStaff) fetchAvailableStaff()
    showSnackbar(['Staff added'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const removeStaff = async (userId) => {
  try {
    const response = await api.delete('/clients/' + route.params.id + '/staff/' + userId)
    staff.value = response.data.staff
    if (canManageStaff) fetchAvailableStaff()
    showSnackbar(['Staff removed'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const fetchIssues = async () => {
  issuesLoading.value = true
  try {
    const response = await issuesApi.getAll({ client_id: route.params.id })
    clientIssues.value = response.data.issues
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    issuesLoading.value = false
  }
}

const issueStatusColor = (status) => {
  if (status === 'active')   return 'success'
  if (status === 'inactive') return 'warning'
  return 'default'
}

onMounted(async () => {
  await fetchClient()
  fetchPeople()
  fetchStaff()
  fetchIssues()
  if (canManageStaff) fetchAvailableStaff()
})

defineExpose({
  client, loading, people, peopleLoading, activeTab, fetchClient, fetchPeople,
  staff, staffLoading, availableStaffOptions, selectedStaff, canManageStaff,
  fetchStaff, fetchAvailableStaff, addStaff, removeStaff,
  clientIssues, issuesLoading, fetchIssues, issueStatusColor
})
</script>
