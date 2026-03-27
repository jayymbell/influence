<script setup>
import { computed } from 'vue'
import useConversationStore from '../stores/ConversationStore'

const store = useConversationStore()

const props = defineProps({
  conversations: { type: Array, required: true },
  currentId: { type: [Number, null], default: null },
})

const emit = defineEmits(['select', 'create', 'delete'])

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const now = new Date()
  const diff = now - d
  if (diff < 86400000) {
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }
  if (diff < 604800000) {
    return d.toLocaleDateString([], { weekday: 'short' })
  }
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' })
}
</script>

<template>
  <div class="conversation-list">
    <div class="conversation-list__header pa-3 d-flex align-center" style="height: 56px;">
      <v-btn
        color="primary"
        block
        prepend-icon="mdi-plus"
        @click="emit('create')"
      >
        New Chat
      </v-btn>
    </div>

    <v-divider />

    <v-list
      v-if="conversations.length"
      density="compact"
      nav
      class="conversation-list__items"
    >
      <v-list-item
        v-for="conv in conversations"
        :key="conv.id"
        :active="conv.id === currentId"
        @click="emit('select', conv)"
        rounded="lg"
        class="mx-2 my-1"
      >
        <template #prepend>
          <v-icon size="small">mdi-chat-outline</v-icon>
        </template>

        <v-list-item-title class="text-body-2 font-weight-medium text-truncate">
          {{ conv.title || 'New conversation' }}
        </v-list-item-title>

        <v-list-item-subtitle class="text-caption">
          {{ formatDate(conv.updated_at) }}
        </v-list-item-subtitle>

        <template #append>
          <v-btn
            icon
            size="x-small"
            variant="text"
            @click.stop="emit('delete', conv.id)"
          >
            <v-icon size="small">mdi-delete-outline</v-icon>
          </v-btn>
        </template>
      </v-list-item>
    </v-list>

    <div v-else class="pa-4 text-center text-medium-emphasis text-body-2">
      No conversations yet.<br />Start a new chat!
    </div>
  </div>
</template>

<style scoped>
.conversation-list {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.conversation-list__items {
  flex: 1;
  overflow-y: auto;
}
</style>
