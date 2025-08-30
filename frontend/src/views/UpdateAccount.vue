<template>
      <v-form @submit.prevent="updateAccount">
        <v-text-field
            v-if="mode == 'edit_email'"
          v-model="email"
          label="Email"
          type="email"
          required
        ></v-text-field>
        <v-text-field
        v-if="mode == 'edit_password'"
          v-model="password"
          label="Password"
          type="password"
        ></v-text-field>
        <v-text-field
        v-if="mode == 'edit_password'"
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
                    <slot name="actions"></slot>
        </v-col>
        <v-col  class="text-right">
          <v-btn type="submit" block>Submit</v-btn>
        </v-col>
      </v-row>
      </v-form>
  </template>
  
  <script>
import { useRouter } from 'vue-router'
import { inject, onMounted, ref } from 'vue'
import useUserStore from '../stores/UserStore'
import { trackEvent } from "../services/ahoy.js";

export default {
  props: {
    mode: String
  },
  setup(props) {  // ✅ emit comes from the second argument
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
        trackEvent("Updated account", { previous_email: userStore.user.email, new_email: email.value })
        await userStore.logout()
        router.push('/login')
        if( props.mode == "edit_email") {
          showSnackbar(['A message with a confirmation link has been sent to your new email address. Please follow the link to re-activate your account.'], 'success')
          return
        }
        else{
            showSnackbar(['Please log back in with your new password.'], 'success')
        }
      } catch (error) {
        console.log(error)
        const errors = error.response?.data?.errors || ['An unknown error occurred']
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
      userStore,
      mode: props.mode
    }
  }
}
</script>
