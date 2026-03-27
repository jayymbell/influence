<script setup>
import { onMounted, computed, inject } from 'vue'
import useConversationStore from '../stores/ConversationStore'
import ConversationList from '../components/ConversationList.vue'
import ChatPanel from '../components/ChatPanel.vue'

const store = useConversationStore()
const showSnackbar = inject('showSnackbar')

const currentId = computed(() => store.currentConversation?.id ?? null)

onMounted(async () => {
  try {
    await store.fetchConversations()
  } catch {
    // Error displayed via store.error snackbar
  }
})

async function handleSelect(conv) {
  try {
    await store.fetchConversation(conv.id)
  } catch {
    // Error displayed via store.error snackbar
  }
}

async function handleCreate() {
  try {
    await store.createConversation()
  } catch {
    // Error displayed via store.error snackbar
  }
}

async function handleDelete(id) {
  try {
    await store.deleteConversation(id)
    showSnackbar(['Conversation deleted'], 'success')
  } catch {
    // Error displayed via store.error snackbar
  }
}
</script>

<template>
  <v-container fluid class="conversations-view pa-0 fill-height">
    <v-row no-gutters class="fill-height">
      <!-- Conversation list sidebar -->
      <v-col cols="3" class="conversations-view__list border-e">
        <ConversationList
          :conversations="store.sortedConversations"
          :current-id="currentId"
          @select="handleSelect"
          @create="handleCreate"
          @delete="handleDelete"
        />
      </v-col>

      <!-- Chat area -->
      <v-col cols="9" class="conversations-view__chat">
        <ChatPanel v-if="store.currentConversation" />

        <div
          v-else
          class="d-flex flex-column align-center justify-center fill-height text-medium-emphasis"
        >
          <v-icon size="80" class="mb-4" color="grey-lighten-1">mdi-forum-outline</v-icon>
          <p class="text-h6 mb-2">General Assistant</p>
          <p class="text-body-2">Select a conversation or start a new one.</p>
        </div>
      </v-col>
    </v-row>

    <!-- Error snackbar from store -->
    <v-snackbar
      v-model="store.error"
      color="error"
      :timeout="3000"
      location="bottom right"
    >
      {{ store.error }}
    </v-snackbar>
  </v-container>
</template>

<style scoped>
.conversations-view {
  height: calc(100vh - 64px); /* subtract app-bar height */
}
.conversations-view__list {
  height: 100%;
  overflow-y: auto;
}
.conversations-view__chat {
  height: 100%;
  min-width: 0;
  overflow: hidden;
}
</style>
