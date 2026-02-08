<template>
    <v-container style="margin-top: 25%;">
      <h1>Reset Password</h1>
      <v-form @submit.prevent="requestPasswordReset">
        <v-text-field v-model="email" label="Email" required></v-text-field>
              <v-row>
        <v-col cols="7">
        </v-col>
        <v-col  class="text-right">
          <v-btn type="submit" block>Submit</v-btn>
        </v-col>
      </v-row>
      </v-form>
    </v-container>
  </template>
  
  <script>
  import api from '../services/api'
  import { useRoute, useRouter } from 'vue-router'
  import { inject } from 'vue'
  
  export default {
    data() {
      return {
        email: ''
      }
    },
    setup() {
      const route = useRoute()
      const router = useRouter()
      const showSnackbar = inject('showSnackbar')
      return { showSnackbar, router, route }
    },
    methods: {
      async requestPasswordReset() {
        try {
          if(this.email.trim() === '') {
          this.showSnackbar(['Please enter your email address.'], 'error')
          return
        }
          const response = await api.post('/password', { user: { email: this.email } })
          this.showSnackbar([response.data.status.message], 'success')
          this.router.push({ name: 'Login' })
        } catch (error) {
          const errors = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(errors, 'error')
        }
      }
    }
  }
  </script>