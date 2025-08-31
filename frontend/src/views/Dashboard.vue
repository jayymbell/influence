<template>
    <v-container>
        <h1>Dashboard</h1>
    </v-container>
  </template>
  
  <script>
  import useUserStore from '../stores/UserStore'
  import { useRouter } from 'vue-router'
  
  export default {
    name: 'Dashboard',
    setup() {
      const userStore = useUserStore()
      const router = useRouter()
      return {
        userStore,
        router
      }
    }
  }
  </script>
  
  <style scoped>
  /* Add styles here */
  </style>