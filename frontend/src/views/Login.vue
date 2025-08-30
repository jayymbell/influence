<template>
  <v-container style="margin-top: 25%;">
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
        trackEvent("Logged in", {});
        this.showSnackbar([response.data.message], 'success')
        this.router.push({ name: 'Dashboard' })
      } catch (error) {
        console.log(error)
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