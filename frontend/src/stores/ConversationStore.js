import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import conversationsApi from '../services/conversations'

const useConversationStore = defineStore('conversations', () => {
  const conversations = ref([])
  const currentConversation = ref(null)
  const loading = ref(false)
  const sending = ref(false)
  const error = ref(null)

  const sortedConversations = computed(() =>
    [...conversations.value].sort(
      (a, b) => new Date(b.updated_at) - new Date(a.updated_at)
    )
  )

  const messages = computed(() =>
    currentConversation.value?.messages ?? []
  )

  // ── Actions ─────────────────────────────────────────────

  async function fetchConversations() {
    loading.value = true
    error.value = null
    try {
      const res = await conversationsApi.getAll()
      conversations.value = res.data.conversations
    } catch (e) {
      error.value = e.response?.data?.message || 'Failed to load conversations'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchConversation(id) {
    loading.value = true
    error.value = null
    try {
      const res = await conversationsApi.get(id)
      currentConversation.value = res.data.conversation
      // Also update in the list
      const idx = conversations.value.findIndex((c) => c.id === id)
      if (idx !== -1) {
        conversations.value[idx] = res.data.conversation
      }
    } catch (e) {
      error.value = e.response?.data?.message || 'Failed to load conversation'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createConversation(title = null) {
    error.value = null
    try {
      const res = await conversationsApi.create(title ? { title } : {})
      const conv = res.data.conversation
      conversations.value.unshift(conv)
      currentConversation.value = conv
      return conv
    } catch (e) {
      error.value = e.response?.data?.message || 'Failed to create conversation'
      throw e
    }
  }

  async function updateConversation(id, data) {
    error.value = null
    try {
      const res = await conversationsApi.update(id, data)
      const conv = res.data.conversation
      const idx = conversations.value.findIndex((c) => c.id === id)
      if (idx !== -1) conversations.value[idx] = conv
      if (currentConversation.value?.id === id) {
        currentConversation.value = conv
      }
      return conv
    } catch (e) {
      error.value = e.response?.data?.message || 'Failed to update conversation'
      throw e
    }
  }

  async function deleteConversation(id) {
    error.value = null
    try {
      await conversationsApi.destroy(id)
      conversations.value = conversations.value.filter((c) => c.id !== id)
      if (currentConversation.value?.id === id) {
        currentConversation.value = null
      }
    } catch (e) {
      error.value = e.response?.data?.message || 'Failed to delete conversation'
      throw e
    }
  }

  async function sendMessage(content) {
    if (!currentConversation.value) return
    sending.value = true
    error.value = null

    // Optimistically add the user message
    const tempMsg = {
      id: `temp-${Date.now()}`,
      role: 'user',
      content,
      created_at: new Date().toISOString(),
    }
    currentConversation.value.messages.push(tempMsg)

    try {
      const res = await conversationsApi.sendMessage(
        currentConversation.value.id,
        content
      )
      // Replace optimistic data with server response
      currentConversation.value = res.data.conversation
      // Update in the list
      const idx = conversations.value.findIndex(
        (c) => c.id === currentConversation.value.id
      )
      if (idx !== -1) {
        conversations.value[idx] = res.data.conversation
      }
    } catch (e) {
      // Remove optimistic message on failure
      currentConversation.value.messages =
        currentConversation.value.messages.filter((m) => m.id !== tempMsg.id)
      error.value =
        e.response?.data?.errors?.[0] ||
        e.response?.data?.message ||
        'Failed to send message'
      throw e
    } finally {
      sending.value = false
    }
  }

  function selectConversation(conv) {
    currentConversation.value = conv
  }

  function clearCurrent() {
    currentConversation.value = null
  }

  return {
    conversations,
    currentConversation,
    loading,
    sending,
    error,
    sortedConversations,
    messages,
    fetchConversations,
    fetchConversation,
    createConversation,
    updateConversation,
    deleteConversation,
    sendMessage,
    selectConversation,
    clearCurrent,
  }
})

export default useConversationStore
