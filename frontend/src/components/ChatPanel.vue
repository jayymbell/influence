<script setup>
import { ref, nextTick, watch, computed } from 'vue'
import useConversationStore from '../stores/ConversationStore'

const store = useConversationStore()

const messageInput = ref('')
const messagesContainer = ref(null)

const messages = computed(() => store.messages)
const sending = computed(() => store.sending)

watch(
  () => messages.value.length,
  async () => {
    await nextTick()
    scrollToBottom()
  }
)

function scrollToBottom() {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

async function handleSend() {
  const content = messageInput.value.trim()
  if (!content || sending.value) return
  messageInput.value = ''

  try {
    await store.sendMessage(content)
  } catch {
    // Error is handled in the store
  }
}

function handleKeydown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    handleSend()
  }
}
</script>

<template>
  <div class="chat-panel">
    <!-- Header -->
    <div class="chat-panel__header pa-3 d-flex align-center" style="height: 56px;">
      <v-icon class="mr-2">mdi-robot-outline</v-icon>
      <span class="text-h6">
        {{ store.currentConversation?.title || 'New conversation' }}
      </span>
    </div>

    <v-divider />

    <!-- Messages -->
    <div ref="messagesContainer" class="chat-panel__messages pa-4">
      <div v-if="!messages.length" class="text-center text-medium-emphasis mt-8">
        <v-icon size="64" class="mb-4" color="grey-lighten-1">mdi-chat-processing-outline</v-icon>
        <p class="text-body-1">Send a message to start the conversation.</p>
      </div>

      <div
        v-for="msg in messages"
        :key="msg.id"
        class="chat-message mb-3"
        :class="msg.role === 'user' ? 'chat-message--user' : 'chat-message--assistant'"
      >
        <div class="chat-message__bubble pa-3">
          <div class="d-flex align-center mb-1">
            <v-icon size="small" class="mr-1">
              {{ msg.role === 'user' ? 'mdi-account' : 'mdi-robot-outline' }}
            </v-icon>
            <span class="text-caption font-weight-bold text-capitalize">
              {{ msg.role }}
            </span>
          </div>
          <div class="chat-message__content text-body-2" style="white-space: pre-wrap;">{{ msg.content }}</div>
        </div>
      </div>

      <!-- Typing indicator -->
      <div v-if="sending" class="chat-message chat-message--assistant mb-3">
        <div class="chat-message__bubble pa-3">
          <div class="d-flex align-center">
            <v-icon size="small" class="mr-1">mdi-robot-outline</v-icon>
            <span class="text-caption font-weight-bold">Assistant</span>
          </div>
          <div class="mt-1">
            <v-progress-linear indeterminate color="primary" height="2" class="mt-1" />
            <span class="text-caption text-medium-emphasis">Thinking…</span>
          </div>
        </div>
      </div>
    </div>

    <v-divider />

    <!-- Input -->
    <div class="chat-panel__input pa-3">
      <v-textarea
        v-model="messageInput"
        placeholder="Type a message…"
        variant="outlined"
        density="compact"
        rows="1"
        max-rows="4"
        auto-grow
        hide-details
        :disabled="sending"
        @keydown="handleKeydown"
      >
        <template #append-inner>
          <v-btn
            icon
            size="small"
            color="primary"
            variant="text"
            :disabled="!messageInput.trim() || sending"
            :loading="sending"
            @click="handleSend"
          >
            <v-icon>mdi-send</v-icon>
          </v-btn>
        </template>
      </v-textarea>
    </div>
  </div>
</template>

<style scoped>
.chat-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.chat-panel__messages {
  flex: 1;
  overflow-y: auto;
}

.chat-message {
  display: flex;
}

.chat-message--user {
  justify-content: flex-end;
}

.chat-message--assistant {
  justify-content: flex-start;
}

.chat-message__bubble {
  max-width: 75%;
  border-radius: 12px;
}

.chat-message--user .chat-message__bubble {
  background-color: rgb(var(--v-theme-primary), 0.1);
  border-bottom-right-radius: 4px;
}

.chat-message--assistant .chat-message__bubble {
  background-color: #f5f5f5;
  border-bottom-left-radius: 4px;
}

.chat-panel__input {
  background: rgb(var(--v-theme-surface));
}
</style>
