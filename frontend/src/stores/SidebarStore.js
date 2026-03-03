import { defineStore } from 'pinia'
import { ref } from 'vue'

const useSidebarStore = defineStore('sidebar', () => {
  const isOpen = ref(false)

  function toggle() {
    isOpen.value = !isOpen.value
  }

  function open() {
    isOpen.value = true
  }

  function close() {
    isOpen.value = false
  }

  return { isOpen, toggle, open, close }
})

export default useSidebarStore
