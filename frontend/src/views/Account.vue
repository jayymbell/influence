<template>
    <v-container style="margin-top: 25%;">
      <h1>Update Account</h1>
      <v-form @submit.prevent="updateAccount">
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
        ></v-text-field>
        <v-text-field
          v-model="password_confirmation"
          label="Confirm Password"
          type="password"
        ></v-text-field>
        <v-text-field
          v-model="current_password"
          label="Current Password"
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
    </v-container>
  </template>
  
  <script>
  import { useRouter } from 'vue-router'
  import { inject, onMounted, ref } from 'vue'
  import useUserStore from '../stores/UserStore'
  import { trackEvent } from "../services/ahoy.js";
  
  export default {
    setup() {
      const router = useRouter()
      const showSnackbar = inject('showSnackbar')
      const userStore = useUserStore()
  
      const email = ref('')
      const password = ref('')
      const password_confirmation = ref('')
      const current_password = ref('')
  
      onMounted(() => {
        email.value = userStore.user.email
      })
  
      const updateAccount = async () => {
        const userStore = useUserStore()
        try {
          const data = {
            user: {
              email: email.value,
              password: password.value,
              password_confirmation: password_confirmation.value,
              current_password: current_password.value
            }
          }
          const response = await userStore.update(data)
          trackEvent("Updated account", {previous_email: userStore.user.email, new_email: email.value})
          showSnackbar([response.data.message], 'success')
          router.push({ name: 'Dashboard' })
        } catch (error) {
          const errors = error.response.data.errors || ['An unknown error occurred']
          showSnackbar(errors, 'error')
        }
      }
  
      return {
        email,
        password,
        password_confirmation,
        current_password,
        updateAccount,
        router,
        showSnackbar,
        userStore
      }
    }
  }
  </script>