<template>
  <v-dialog :model-value="modelValue" max-width="760" @update:model-value="$emit('update:modelValue', $event)" @keydown.esc="close">
    <v-card>
      <v-card-title class="pt-5 px-6">
        {{ mode === 'import' ? 'Search Open States' : 'Link to Open States' }}
      </v-card-title>

      <v-card-text class="px-6">
        <v-text-field
          v-model="query"
          label="Search by bill number or keyword"
          placeholder="e.g. HF 100, education funding"
          autofocus
          clearable
          @update:model-value="debouncedSearch"
          @click:clear="clearSearch"
        />

        <!-- Loading -->
        <template v-if="searching">
          <v-skeleton-loader v-for="n in 3" :key="n" type="list-item-two-line" class="mb-1" />
        </template>

        <!-- Error -->
        <v-alert v-else-if="error" type="error" variant="tonal" class="mb-2">
          {{ error }}
        </v-alert>

        <!-- Results -->
        <template v-else-if="results.length">
          <v-table hover>
            <thead>
              <tr>
                <th>Bill Number</th>
                <th>Title</th>
                <th>Chamber</th>
                <th>Session</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="result in results" :key="result.external_id">
                <td class="text-no-wrap">{{ result.bill_number || '—' }}</td>
                <td>{{ result.title }}</td>
                <td class="text-no-wrap">{{ result.chamber || '—' }}</td>
                <td class="text-no-wrap">{{ result.session_year || '—' }}</td>
                <td class="text-right text-no-wrap">
                  <template v-if="mode === 'import'">
                    <v-chip
                      v-if="result.already_imported"
                      size="small"
                      color="success"
                      variant="tonal"
                      :to="alreadyImportedLink(result)"
                      @click="close"
                    >Already Imported</v-chip>
                    <v-btn
                      v-else
                      size="small"
                      color="primary"
                      :loading="actionLoadingId === result.external_id"
                      :disabled="!!actionLoadingId"
                      @click="handleImport(result)"
                    >Import</v-btn>
                  </template>
                  <template v-else>
                    <v-btn
                      size="small"
                      color="primary"
                      :loading="actionLoadingId === result.external_id"
                      :disabled="!!actionLoadingId"
                      @click="handleLink(result)"
                    >Link</v-btn>
                  </template>
                </td>
              </tr>
            </tbody>
          </v-table>
        </template>

        <!-- Empty state after search -->
        <p v-else-if="searched && !searching" class="text-medium-emphasis mt-2">
          No results found for "{{ query }}".
        </p>

        <!-- Initial prompt -->
        <p v-else class="text-medium-emphasis mt-2">
          Type a keyword or bill number to search Minnesota bills.
        </p>
      </v-card-text>

      <v-card-actions class="px-6 pb-5">
        <v-spacer />
        <v-btn variant="text" @click="close">Cancel</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref, watch, inject } from 'vue'
import { useRouter } from 'vue-router'
import { debounce } from 'lodash'
import billsApi from '../services/bills.js'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  mode:       { type: String, default: 'import' }, // 'import' | 'link'
  billId:     { type: [Number, String], default: null },
})

const emit = defineEmits(['update:modelValue', 'linked'])

const router       = useRouter()
const showSnackbar = inject('showSnackbar')

const query           = ref('')
const results         = ref([])
const searching       = ref(false)
const searched        = ref(false)
const error           = ref(null)
const actionLoadingId = ref(null)

// Reset state when dialog opens
watch(() => props.modelValue, (open) => {
  if (open) {
    query.value           = ''
    results.value         = []
    searched.value        = false
    error.value           = null
    actionLoadingId.value = null
  }
})

const doSearch = async () => {
  if (!query.value?.trim()) {
    results.value  = []
    searched.value = false
    return
  }
  searching.value = true
  error.value     = null
  try {
    const response = await billsApi.search(query.value.trim())
    results.value  = response.data.results || []
    searched.value = true
  } catch (e) {
    error.value   = e.response?.data?.errors?.[0] || 'Search failed. Please try again.'
    results.value = []
  } finally {
    searching.value = false
  }
}

const debouncedSearch = debounce(doSearch, 400)

const clearSearch = () => {
  results.value  = []
  searched.value = false
  error.value    = null
}

const handleImport = async (result) => {
  actionLoadingId.value = result.external_id
  try {
    const response = await billsApi.importBill(result.external_id)
    const bill     = response.data.bill
    close()
    router.push({ name: 'BillShow', params: { id: bill.id } })
  } catch (e) {
    const msg = e.response?.data?.errors?.[0] || 'Import failed.'
    showSnackbar([msg], 'error')
  } finally {
    actionLoadingId.value = null
  }
}

const handleLink = async (result) => {
  actionLoadingId.value = result.external_id
  try {
    await billsApi.linkExternal(props.billId, result.external_id)
    close()
    emit('linked')
  } catch (e) {
    const msg = e.response?.data?.errors?.[0] || 'Link failed.'
    showSnackbar([msg], 'error')
  } finally {
    actionLoadingId.value = null
  }
}

const close = () => {
  emit('update:modelValue', false)
}

const alreadyImportedLink = (result) => {
  return result.internal_id ? { name: 'BillShow', params: { id: result.internal_id } } : null
}

defineExpose({
  query, results, searching, searched, error, actionLoadingId,
  doSearch, debouncedSearch, clearSearch, handleImport, handleLink, close, alreadyImportedLink,
})
</script>
