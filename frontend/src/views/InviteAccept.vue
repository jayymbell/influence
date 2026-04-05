<template>
  <v-container class="d-flex align-center justify-center" style="min-height: calc(100vh - 64px);">
    <v-col cols="12" sm="8" md="5">
      <h1 class="mb-2">Create your account</h1>
      <p class="text-medium-emphasis mb-6">Choose a password to finish setting up your account.</p>

      <v-card class="pa-6">
        <v-text-field
          v-model="password"
          label="Password"
          type="password"
          class="mb-2"
        />
        <v-text-field
          v-model="passwordConfirmation"
          label="Confirm Password"
          type="password"
        />

        <v-row class="mt-4">
          <v-col class="text-right">
            <v-btn color="primary" :loading="saving" @click="submit">Create Account</v-btn>
          </v-col>
        </v-row>
      </v-card>
    </v-col>
  </v-container>
</template>

<script setup>
import { ref, inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'
import useUserStore from '../stores/UserStore.js'

const route  = useRoute()
const router = useRouter()
const userStore  = useUserStore()
const showSnackbar = inject('showSnackbar')

const password             = ref('')
const passwordConfirmation = ref('')
const saving               = ref(false)

const submit = async () => {
  saving.value = true
  try {
    const response = await api.post('/invitations/accept', {
      token:                 route.query.token,
      password:              password.value,
      password_confirmation: passwordConfirmation.value
    })

    const { token, refresh_token, user } = response.data

    // Bootstrap store exactly like login does
    userStore.bearerToken = token
    localStorage.setItem('bearerToken', token)
    userStore.user = user
    localStorage.setItem('user', JSON.stringify(user))
    api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    localStorage.setItem('refreshToken', refresh_token)

    router.push({ name: 'Dashboard' })
  } catch (error) {
    const errors = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(errors, 'error')
  } finally {
    saving.value = false
  }
}
</script>
