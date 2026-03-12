<template>
  <v-container class="d-flex align-center justify-center" style="height: calc(100vh - 64px);">
    <div>
    <h1>Sign Up</h1>
    <v-form @submit.prevent="handleSignup">
      <v-text-field
        v-model="email"
        label="Email"
        type="email"
        required
      ></v-text-field>
      <v-text-field
        v-model="password"
        label="Password"
        type="password"
        required
      ></v-text-field>
      <v-text-field
        v-model="password_confirmation"
        label="Confirm Password"
        type="password"
        required
      ></v-text-field>
            <v-row>
        <v-col cols="7">

        </v-col>
        <v-col  class="text-right">
          <v-btn type="submit" block>Submit</v-btn>
        </v-col>
      </v-row>

    </v-form>
    </div>
  </v-container>
</template>

<script>
import { useRouter } from 'vue-router'
import { inject } from 'vue'
import api from '../services/api'

export default {
  data() {
    return {
      email: '',
      password: '',
      password_confirmation: ''
    }
  },
  setup() {
    const router = useRouter()
    const showSnackbar = inject('showSnackbar')
    return { router, showSnackbar }
  },
  methods: {
    async handleSignup() {
      const data = {user: {email: this.email, password: this.password, password_confirmation: this.password_confirmation}}
      try {
        const response = await api.post('/signup',data)
        this.showSnackbar([response.data.message], 'success')
        this.router.push({ name: 'Login' })
      } catch (error) {
        const errors = error.response.data.errors || ['An unknown error occurred']
        this.showSnackbar(errors, 'error')
      }
    }
  }
}
</script>