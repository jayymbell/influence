<template>
  <v-container class="d-flex align-center justify-center" style="height: calc(100vh - 64px);">
    <div>
    <h1>Log In</h1>
    <v-form @submit.prevent="handleLogin">
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
      <v-row>
        <v-col cols="7">
          <a @click="redirectToPasswordReset" block>Forgot Password?</a>
        </v-col>
        <v-col  class="text-right">
          <v-btn type="submit" block class="no-overlay">Submit</v-btn>
        </v-col>
      </v-row>
    </v-form>
    </div>
  </v-container>
</template>

<script>
import useUserStore from '../stores/UserStore'
import { useRouter } from 'vue-router'
import { inject } from 'vue'
import { trackEvent } from "../services/ahoy.js";

export default {
  data() {
    return {
      email: '',
      password: ''
    }
  },
  setup() {
    const router = useRouter()
    const showSnackbar = inject('showSnackbar')
    return { router, showSnackbar }
  },
  methods: {
    async handleLogin() {
      const userStore = useUserStore()
      const data = {user: {email: this.email, password: this.password}}
      try {
        if(this.email === '' || this.password === '') {
          this.showSnackbar(['Please enter your email and password.'], 'error')
          return
        }
        const response = await userStore.login(data)
        this.showSnackbar([response.data.status.message], 'success')
        this.router.push({ name: 'Dashboard' })
      } catch (error) {
        const e = error.response.data.error || ['An unknown error occurred']
        this.showSnackbar([e], 'error')
      }
    },
    redirectToPasswordReset() {
      this.router.push({ name: 'PasswordReset' })
    }
  }
}
</script>