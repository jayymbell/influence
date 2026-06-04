<template>
  <v-container>
    <v-btn variant="text" :to="{ name: 'BillShow', params: { id: billId } }" class="mb-4 pl-0">
      &larr; Back to Bill
    </v-btn>

    <template v-if="loading">
      <v-skeleton-loader type="article" />
    </template>

    <template v-else-if="error">
      <v-alert type="error" variant="tonal">{{ error }}</v-alert>
    </template>

    <template v-else-if="note">
      <v-card>
        <v-card-text class="pa-6">
          <h2 v-if="note.title" class="text-h5 mb-2">{{ note.title }}</h2>

          <p class="text-caption text-medium-emphasis mb-4">
            {{ note.author }} &middot; {{ formatDateTime(note.created_at) }}
          </p>

          <!-- eslint-disable-next-line vue/no-v-html -->
          <div class="note-content" v-html="note.content" />
        </v-card-text>
      </v-card>
    </template>
  </v-container>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import billsApi from '../services/bills.js'

const route = useRoute()
const billId = route.params.billId
const noteId = route.params.noteId

const note    = ref(null)
const loading = ref(false)
const error   = ref(null)

const formatDateTime = (isoString) => {
  if (!isoString) return ''
  return new Date(isoString).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit',
  })
}

onMounted(async () => {
  loading.value = true
  try {
    const response = await billsApi.getNote(billId, noteId)
    note.value = response.data.note
  } catch (err) {
    const status = err.response?.status
    if (status === 403 || status === 404) {
      error.value = 'This note is not available. It may be private or no longer exist.'
    } else {
      error.value = 'Failed to load note.'
    }
  } finally {
    loading.value = false
  }
})
</script>

<style>
.note-content p { margin-bottom: 0.4em; }
.note-content ul, .note-content ol { padding-left: 1.5em; margin-bottom: 0.4em; }
.note-content blockquote { border-left: 3px solid #ccc; padding-left: 1em; color: #666; }
.note-content h2 { font-size: 1.3em; font-weight: 600; margin: 0.6em 0 0.3em; }
.note-content h3 { font-size: 1.1em; font-weight: 600; margin: 0.5em 0 0.2em; }
</style>
