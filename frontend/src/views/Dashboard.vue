<template>
    <v-container>
        <h1>Dashboard</h1>
        <v-btn v-if="userStore.hasRole('admin')" to="/roles" style="width: 100%; margin-top: 10px;"> Roles</v-btn>
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