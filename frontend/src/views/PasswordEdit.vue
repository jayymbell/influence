<template>
    <v-container style="margin-top: 25%;">
      <h1>New Password</h1>
        <v-form @submit.prevent="resetPassword">
        <v-text-field v-model="password" label="New Password" type="password" required></v-text-field>
        <v-text-field v-model="password_confirmation" label="Confirm Password" type="password" required></v-text-field>
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
        password: '',
        password_confirmation: ''
      }
    },
    setup() {
      const route = useRoute()
      const router = useRouter()
      const showSnackbar = inject('showSnackbar')
      return { route, router, showSnackbar }
    },
    methods: {
      async resetPassword() {
        const reset_password_token = this.route.query.reset_password_token
        try {
          if(this.password === '' || this.password_confirmation === '') {
          this.showSnackbar(['Please enter your new password.'], 'error')
          return
        }
          const response = await api.put('/password', {
            user: {
              reset_password_token,
              password: this.password,
              password_confirmation: this.password_confirmation
            }
          })
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