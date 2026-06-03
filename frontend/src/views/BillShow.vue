<template>
  <v-container>
    <v-btn variant="text" :to="{ name: 'Bills' }" class="mb-4 pl-0">&larr; Bills</v-btn>

    <!-- Loading -->
    <template v-if="loading">
      <v-skeleton-loader type="article" />
    </template>

    <!-- Bill detail -->
    <template v-else-if="bill">
      <v-row align="center" class="mb-1">
        <v-col>
          <h1>
            <span v-if="bill.bill_number" class="text-medium-emphasis mr-2">{{ bill.bill_number }}</span>
            {{ bill.title }}
            <v-chip
              size="small"
              :color="statusColor(bill.status)"
              variant="tonal"
              class="ml-2"
            >{{ formatStatus(bill.status) }}</v-chip>
            <v-chip
              v-if="bill.chamber"
              size="small"
              :color="chamberColor(bill.chamber)"
              variant="tonal"
              class="ml-1"
            >{{ bill.chamber }}</v-chip>
            <v-chip
              v-if="bill.session_year"
              size="small"
              variant="outlined"
              class="ml-1"
            >{{ bill.session_year }}</v-chip>
          </h1>
          <div v-if="bill.tags?.length" class="mt-1">
            <v-chip
              v-for="tag in bill.tags"
              :key="tag"
              size="x-small"
              variant="outlined"
              class="mr-1"
            >{{ tag }}</v-chip>
          </div>
          <div v-if="revisorUrl" class="mt-1 text-body-2">
            <a :href="revisorUrl" target="_blank" rel="noopener noreferrer">MN Revisor ↗</a>
          </div>
          <div v-if="bill.companion_bill" class="mt-1 text-body-2 text-medium-emphasis">
            Companion:
            <router-link :to="{ name: 'BillShow', params: { id: bill.companion_bill.id } }">
              {{ bill.companion_bill.bill_number || bill.companion_bill.title }}
            </router-link>
          </div>
        </v-col>
        <v-col cols="auto">
          <v-btn variant="outlined" size="small" @click="openEditDialog">Edit</v-btn>
          <v-btn
            v-if="!bill.external_id"
            variant="outlined"
            size="small"
            class="ml-2"
            @click="linkModalOpen = true"
          >Link to Open States</v-btn>
          <template v-else>
            <v-btn
              variant="outlined"
              size="small"
              class="ml-2"
              :loading="refreshing"
              @click="doRefresh"
            >Refresh</v-btn>
            <v-btn
              variant="outlined"
              size="small"
              class="ml-2"
              :loading="importingAuthors"
              @click="doImportAuthors"
            >Import Authors</v-btn>
            <v-tooltip :text="bill.last_synced_at">
              <template #activator="{ props: tooltipProps }">
                <span v-bind="tooltipProps" class="ml-2 text-caption text-medium-emphasis" style="cursor:default">
                  Synced {{ relativeTime(bill.last_synced_at) }}
                </span>
              </template>
            </v-tooltip>
          </template>
        </v-col>
      </v-row>

      <!-- Description / Notes -->
      <v-row v-if="bill.description || bill.notes" class="mt-2">
        <v-col v-if="bill.description" cols="12" md="6">
          <p class="text-body-2 text-medium-emphasis mb-1">Description</p>
          <p class="text-body-1">{{ bill.description }}</p>
        </v-col>
        <v-col v-if="bill.notes" cols="12" md="6">
          <p class="text-body-2 text-medium-emphasis mb-1">Notes</p>
          <p class="text-body-1">{{ bill.notes }}</p>
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-tabs v-model="activeTab" class="mt-4">
        <v-tab value="issues">Issues</v-tab>
        <v-tab value="clients">Clients</v-tab>
        <v-tab value="people">People</v-tab>
        <v-tab value="activity">Activity</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="activeTab" class="mt-4">
        <!-- Issues tab -->
        <v-window-item value="issues">
          <v-row align="center" class="mb-2">
            <v-col cols="8">
              <v-autocomplete
                v-model="selectedIssue"
                :items="availableIssueOptions"
                label="Link issue"
                clearable
                no-data-text="No issues available"
              />
            </v-col>
            <v-col cols="auto">
              <v-btn color="primary" :disabled="!selectedIssue" @click="linkIssue">Link</v-btn>
            </v-col>
          </v-row>

          <template v-if="issuesLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>
          <template v-else>
            <v-table v-if="bill.issues?.length" hover>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="issue in bill.issues" :key="issue.id">
                  <td>
                    <router-link :to="{ name: 'IssueShow', params: { id: issue.id } }">{{ issue.title }}</router-link>
                  </td>
                  <td>
                    <v-chip size="x-small" variant="tonal">{{ issue.status }}</v-chip>
                  </td>
                  <td class="text-right">
                    <v-btn variant="text" size="small" color="error" @click="unlinkIssue(issue.id)">Unlink</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>
            <p v-else class="text-medium-emphasis mt-4">No issues linked to this bill.</p>
          </template>
        </v-window-item>

        <!-- Clients tab -->
        <v-window-item value="clients">
          <v-row align="center" class="mb-2">
            <v-col cols="8">
              <v-autocomplete
                v-model="selectedClient"
                :items="availableClientOptions"
                label="Link client"
                clearable
                no-data-text="No clients available"
              />
            </v-col>
            <v-col cols="auto">
              <v-btn color="primary" :disabled="!selectedClient" @click="linkClient">Link</v-btn>
            </v-col>
          </v-row>

          <template v-if="clientsLoading">
            <v-skeleton-loader v-for="n in 3" :key="n" type="list-item" class="mb-2" />
          </template>
          <template v-else>
            <v-table v-if="bill.clients?.length" hover>
              <thead>
                <tr>
                  <th>Client</th>
                  <th>Linked</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in bill.clients" :key="c.id">
                  <td>{{ c.display_name }}</td>
                  <td>{{ c.shared_at ? new Date(c.shared_at).toLocaleDateString() : '—' }}</td>
                  <td class="text-right">
                    <v-btn variant="text" size="small" color="error" @click="unlinkClient(c.id)">Unlink</v-btn>
                  </td>
                </tr>
              </tbody>
            </v-table>
            <p v-else class="text-medium-emphasis mt-4">No clients linked to this bill.</p>
          </template>
        </v-window-item>

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
            <v-table v-if="bill.people?.length" hover>
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
                <tr v-for="p in bill.people" :key="p.id">
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
            <p v-else class="text-medium-emphasis mt-4">No people added to this bill.</p>
          </template>
        </v-window-item>

        <!-- Activity tab -->
        <v-window-item value="activity">
          <template v-if="bill.actions?.length">
            <v-timeline density="compact" side="end" class="mt-2">
              <v-timeline-item
                v-for="action in bill.actions"
                :key="action.id"
                :dot-color="actionColor(action.classification)"
                size="x-small"
              >
                <div class="d-flex align-center ga-2 flex-wrap">
                  <span class="text-caption text-medium-emphasis text-no-wrap">{{ formatDate(action.action_date) }}</span>
                  <span>{{ action.description }}</span>
                  <v-chip
                    v-for="cls in action.classification"
                    :key="cls"
                    size="x-small"
                    variant="tonal"
                    :color="actionColor([cls])"
                  >{{ cls }}</v-chip>
                </div>
              </v-timeline-item>
            </v-timeline>
          </template>
          <p v-else class="text-medium-emphasis mt-4">No activity recorded. Refresh the bill to sync from Open States.</p>
        </v-window-item>
      </v-window>
    </template>

    <template v-else>
      <p class="text-medium-emphasis">Bill not found.</p>
    </template>

    <!-- Edit dialog -->
    <v-dialog v-model="editDialogOpen" max-width="680" persistent>
      <v-card>
        <v-card-title class="pt-5 px-6">Edit Bill</v-card-title>
        <v-card-text class="px-6">
          <v-row>
            <v-col cols="12">
              <v-text-field v-model="form.title" label="Title *" />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model="form.bill_number" label="Bill Number" />
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
        </v-card-text>
        <v-card-actions class="px-6 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="editDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" @click="saveEdit">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Open States search/link modal -->
    <BillSearchModal
      v-model="linkModalOpen"
      mode="link"
      :bill-id="bill?.id"
      @linked="onLinked"
    />
  </v-container>
</template>

<script setup>
import { onMounted, ref, inject, computed } from 'vue'
import { useRoute } from 'vue-router'
import billsApi from '../services/bills.js'
import api from '../services/api.js'
import BillSearchModal from '../components/BillSearchModal.vue'

const route = useRoute()
const showSnackbar = inject('showSnackbar')

const bill = ref(null)
const loading = ref(false)
const activeTab = ref('issues')
const editDialogOpen = ref(false)
const linkModalOpen  = ref(false)
const refreshing        = ref(false)
const importingAuthors  = ref(false)
const issuesLoading = ref(false)
const clientsLoading = ref(false)
const peopleLoading = ref(false)
const selectedIssue = ref(null)
const selectedClient = ref(null)
const selectedPerson = ref(null)
const availableIssueOptions = ref([])
const availableClientOptions = ref([])
const availablePeopleOptions = ref([])

const form = ref({ title: '', bill_number: '', chamber: null, session_year: null, status: 'introduced', description: '', notes: '', tags: [] })

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

const actionColor = (classifications) => {
  const cls = classifications || []
  if (cls.includes('became-law') || cls.includes('executive-signature')) return 'success'
  if (cls.includes('executive-veto') || cls.includes('failure') || cls.includes('committee-failure')) return 'error'
  if (cls.includes('passage')) return 'teal'
  if (cls.includes('reading-3') || cls.includes('reading-2')) return 'orange'
  if (cls.includes('committee-passage')) return 'cyan'
  if (cls.includes('referral-committee')) return 'indigo'
  if (cls.includes('introduced')) return 'blue'
  return 'grey'
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

const revisorUrl = computed(() => {
  if (!bill.value?.bill_number || !bill.value?.session_year) return null
  const m = bill.value.bill_number.trim().match(/^([A-Za-z]+)\s*(\d+)$/)
  if (!m) return null
  const type   = m[1].toUpperCase()
  const number = m[2]
  const year   = Number(bill.value.session_year)
  const oddYear    = year % 2 === 0 ? year - 1 : year
  const legislature = 94 - ((2025 - oddYear) / 2)
  const body = bill.value.chamber === 'senate' ? 'senate' : 'house'
  return `https://www.revisor.mn.gov/bills/${legislature}/${year}/0/${type}/${number}/?body=${body}`
})

const fetchBill = async () => {
  loading.value = true
  try {
    const response = await billsApi.get(route.params.id)
    bill.value = response.data.bill
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    loading.value = false
  }
}

const fetchAvailableIssues = async () => {
  try {
    const response = await api.get('/issues')
    const linkedIds = (bill.value?.issues || []).map((i) => i.id)
    availableIssueOptions.value = (response.data.issues || [])
      .filter((i) => !linkedIds.includes(i.id))
      .map((i) => ({ title: i.title, value: i.id }))
  } catch (_) { /* silent */ }
}

const fetchAvailableClients = async () => {
  try {
    const response = await api.get('/clients')
    const linkedIds = (bill.value?.clients || []).map((c) => c.id)
    availableClientOptions.value = (response.data.clients || [])
      .filter((c) => !linkedIds.includes(c.id))
      .map((c) => ({ title: c.display_name, value: c.id }))
  } catch (_) { /* silent */ }
}

const fetchAvailablePeople = async () => {
  try {
    const response = await api.get('/people')
    const linkedIds = (bill.value?.people || []).map((p) => p.id)
    availablePeopleOptions.value = (response.data.people || [])
      .filter((p) => !linkedIds.includes(p.id))
      .map((p) => ({
        title:    p.display_name,
        subtitle: [p.title, p.organization_name].filter(Boolean).join(' · ') || undefined,
        value:    p.id,
      }))
  } catch (_) { /* silent */ }
}

const openEditDialog = () => {
  form.value = {
    title:        bill.value.title || '',
    bill_number:  bill.value.bill_number || '',
    chamber:      bill.value.chamber || null,
    session_year: bill.value.session_year || null,
    status:       bill.value.status || 'introduced',
    description:  bill.value.description || '',
    notes:        bill.value.notes || '',
    tags:         bill.value.tags || [],
  }
  editDialogOpen.value = true
}

const saveEdit = async () => {
  try {
    const response = await billsApi.update(bill.value.id, form.value)
    bill.value = response.data.bill
    editDialogOpen.value = false
    showSnackbar(['Bill updated.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  }
}

const linkIssue = async () => {
  issuesLoading.value = true
  try {
    const response = await billsApi.linkIssue(bill.value.id, selectedIssue.value)
    bill.value.issues = response.data.issues
    selectedIssue.value = null
    fetchAvailableIssues()
    showSnackbar(['Issue linked.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    issuesLoading.value = false
  }
}

const unlinkIssue = async (issueId) => {
  issuesLoading.value = true
  try {
    const response = await billsApi.unlinkIssue(bill.value.id, issueId)
    bill.value.issues = response.data.issues
    fetchAvailableIssues()
    showSnackbar(['Issue unlinked.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    issuesLoading.value = false
  }
}

const linkClient = async () => {
  clientsLoading.value = true
  try {
    const response = await billsApi.linkClient(bill.value.id, selectedClient.value)
    bill.value.clients = response.data.clients
    selectedClient.value = null
    fetchAvailableClients()
    showSnackbar(['Client linked.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    clientsLoading.value = false
  }
}

const unlinkClient = async (clientId) => {
  clientsLoading.value = true
  try {
    const response = await billsApi.unlinkClient(bill.value.id, clientId)
    bill.value.clients = response.data.clients
    fetchAvailableClients()
    showSnackbar(['Client unlinked.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    clientsLoading.value = false
  }
}

const addPerson = async () => {
  peopleLoading.value = true
  try {
    const response = await billsApi.addPerson(bill.value.id, selectedPerson.value)
    bill.value.people = response.data.people
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
    const response = await billsApi.removePerson(bill.value.id, personId)
    bill.value.people = response.data.people
    fetchAvailablePeople()
    showSnackbar(['Person removed.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    peopleLoading.value = false
  }
}

const doRefresh = async () => {
  refreshing.value = true
  try {
    const response = await billsApi.refresh(bill.value.id)
    bill.value = response.data.bill
    showSnackbar(['Bill refreshed.'], 'success')
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    refreshing.value = false
  }
}

const doImportAuthors = async () => {
  importingAuthors.value = true
  try {
    const response = await billsApi.importAuthors(bill.value.id)
    const { added, skipped, errors } = response.data
    const msgs = []
    if (added.length)   msgs.push(`Added: ${added.map((p) => p.display_name).join(', ')}`)
    if (skipped.length) msgs.push(`Already linked: ${skipped.map((p) => p.display_name).join(', ')}`)
    if (errors.length)  msgs.push(`Errors: ${errors.join('; ')}`)
    showSnackbar(msgs.length ? msgs : [response.data.message || 'Done.'], 'success')
    await fetchBill()
    fetchAvailablePeople()
  } catch (error) {
    const e = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(e, 'error')
  } finally {
    importingAuthors.value = false
  }
}

const onLinked = async () => {
  await fetchBill()
  showSnackbar(['Bill linked to Open States.'], 'success')
}

const relativeTime = (isoString) => {
  if (!isoString) return ''
  const diff = Date.now() - new Date(isoString).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  return `${Math.floor(hrs / 24)}d ago`
}

onMounted(async () => {
  await fetchBill()
  fetchAvailableIssues()
  fetchAvailableClients()
  fetchAvailablePeople()
})

defineExpose({
  bill, loading, activeTab, editDialogOpen, linkModalOpen, refreshing, form,
  selectedIssue, selectedClient, selectedPerson,
  availableIssueOptions, availableClientOptions, availablePeopleOptions,
  fetchBill, openEditDialog, saveEdit,
  linkIssue, unlinkIssue, linkClient, unlinkClient, addPerson, removePerson,
  doRefresh, onLinked, relativeTime,
  statusColor, chamberColor, formatStatus,
})
</script>
