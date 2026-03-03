<script setup>
import useUserStore from './stores/UserStore'
import useSidebarStore from './stores/SidebarStore'
import SidebarMenu from './components/SidebarMenu.vue'
import { computed, ref, provide } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const userStore = useUserStore()
const sidebarStore = useSidebarStore()
const isLoggedIn = computed(() => userStore.isLoggedIn)
const route = useRoute()
const router = useRouter()

// Snackbar state
const snackbar = ref(false)
const snackbarColor = ref('error')
const snackbarMessages = ref([])

const goToLogin = () => {
  router.push({ name: 'Login' })
}

const goToSignUp = () => {
  router.push({ name: 'Signup' })
}

const goToDashboard = () => {
  router.push({ name: 'Dashboard' })
}

const showSnackbar = (messages, color = 'error') => {
  snackbarMessages.value = messages
  snackbarColor.value = color
  snackbar.value = true
}

const logout = async () => {
  const response = await userStore.logout()
  showSnackbar([response.data.message], 'success')
  router.push({ name: 'Login' })
}


// Provide the showSnackbar function to child components
provide('showSnackbar', showSnackbar)
</script>

<template>
  <v-app>
    <v-app-bar theme="dark">
      <v-app-bar-nav-icon
        v-if="isLoggedIn"
        @click="sidebarStore.toggle()"
      />
      <v-toolbar-title><a @click="goToDashboard">My App</a></v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn v-if="isLoggedIn" @click="logout">Log out</v-btn>
      <v-btn text v-else-if="!isLoggedIn && route.name !== 'Login'" @click="goToLogin">Log In</v-btn>
      <v-btn text v-else-if="route.name === 'Login'" @click="goToSignUp">Sign Up</v-btn>
  </v-app-bar>
  <SidebarMenu v-if="isLoggedIn" />
  <v-main>
    <router-view />
  </v-main>
    <v-snackbar v-model="snackbar" :timeout="2000" :color="snackbarColor" location="top right" style="margin-right: 5px;">
      <ul v-if="snackbarMessages.length > 1" style="padding-left: 10px;">
        <li v-for="message in snackbarMessages" :key="message">{{ message }}</li>
      </ul>
      <span v-if="snackbarMessages.length === 1">{{ snackbarMessages[0] }}</span>
    </v-snackbar>
  </v-app>
</template>

<style scoped>
.logo {
  /* existing styles */
}
</style>