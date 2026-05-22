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
      </v-window>
    </template>
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import api from '../services/api.js'

const route = useRoute()
const showSnackbar = inject('showSnackbar')

const client = ref(null)
const loading = ref(false)
const people = ref([])
const peopleLoading = ref(false)
const activeTab = ref('contacts')

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

onMounted(async () => {
  await fetchClient()
  fetchPeople()
})

defineExpose({ client, loading, people, peopleLoading, activeTab, fetchClient, fetchPeople })
</script>
