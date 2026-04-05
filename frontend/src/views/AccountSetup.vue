<template>
  <v-container max-width="700">
    <v-row justify="center" class="mt-8">
      <v-col>
        <h1 class="mb-1">Welcome!</h1>
        <p class="text-medium-emphasis mb-6">
          Before you continue, please fill in your details below.
          This only takes a moment.
        </p>

        <v-card class="pa-6">
          <PersonForm :form="form" hide-email hide-notes />

          <v-row class="mt-4">
            <v-col class="text-right">
              <v-btn color="primary" :loading="saving" @click="submit">Save and Continue</v-btn>
            </v-col>
          </v-row>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref, inject } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api.js'
import { trackEvent } from '../services/ahoy.js'
import useUserStore from '../stores/UserStore.js'
import PersonForm from '../components/PersonForm.vue'

const router = useRouter()
const userStore = useUserStore()
const showSnackbar = inject('showSnackbar')
const saving = ref(false)

const form = ref({
  first_name: '',
  last_name: '',
  display_name: '',
  phone: '',
  title: '',
  organization_name: '',
  notes: ''
})

const submit = async () => {
  saving.value = true
  try {
    const response = await api.post('/people', { person: form.value })
    const person = response.data.person
    trackEvent('completed profile setup', { person_id: person.id })
    userStore.setPersonId(person.id)
    router.push({ name: 'Dashboard' })
  } catch (error) {
    const errors = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(errors, 'error')
  } finally {
    saving.value = false
  }
}
</script>
