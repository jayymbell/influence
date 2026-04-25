<template>
  <v-container>
    <h1>Account</h1>

    <div v-if="mode == 'view'">
      <h2>User</h2>
      <v-card class="pa-3 mt-3" outlined style="width: 500px;">
        {{ userStore.user.email }}
        <br>
        member since {{ est }}
        <br>
        <span v-if="roles.length">{{ roles }}</span>
        <br><br>
        <a @click="mode = 'change_email'">Change Email</a> | <a @click="mode = 'change_password'">Change Password</a>
      </v-card>
    </div>

    <div v-if="mode != 'view'">
      <h2>{{ form_title }}</h2>
      <UpdateAccount :mode="mode">
        <template #actions>
          <a @click="mode = 'view'">Close</a>
        </template>
      </UpdateAccount>
    </div>

    <template v-if="userStore.hasPerson">
      <h2 class="mt-6">Profile</h2>

      <v-card class="pa-4 mt-3" style="width: 500px;">
        <template v-if="loadingProfile">
          <v-skeleton-loader type="text" class="mb-3" />
          <v-skeleton-loader type="text" class="mb-3" />
          <v-skeleton-loader type="text" class="mb-3" />
          <v-skeleton-loader type="text" />
        </template>

        <template v-else>
          <PersonForm :form="personForm" hide-email hide-notes />
          <v-row class="mt-2">
            <v-col class="text-right">
              <v-btn color="primary" :loading="savingProfile" @click="saveProfile">Save</v-btn>
            </v-col>
          </v-row>
        </template>
      </v-card>
    </template>
  </v-container>
</template>

<script setup>
import { inject, computed, ref, onMounted } from 'vue'
import _ from 'lodash'
import useUserStore from '../stores/UserStore'
import UpdateAccount from '../components/UpdateAccount.vue'
import PersonForm from '../components/PersonForm.vue'

const showSnackbar = inject('showSnackbar')
const userStore = useUserStore()
const mode = ref('view')
const loadingProfile = ref(false)
const savingProfile = ref(false)

const personForm = ref({
  first_name: '',
  last_name: '',
  display_name: '',
  phone: '',
  title: '',
  organization_name: '',
})

const est = computed(() => new Date(userStore.user.created_at).getFullYear())
const form_title = computed(() => _.startCase(mode.value))
const roles = computed(() => userStore.user.roles.map(r => r.name).join(', '))

onMounted(async () => {
  if (!userStore.hasPerson) return
  loadingProfile.value = true
  try {
    const person = await userStore.fetchPerson(userStore.user.person_id)
    personForm.value = {
      first_name: person.first_name || '',
      last_name: person.last_name || '',
      display_name: person.display_name || '',
      phone: person.phone || '',
      title: person.title || '',
      organization_name: person.organization_name || '',
    }
  } catch {
    showSnackbar(['Failed to load profile.'], 'error')
  } finally {
    loadingProfile.value = false
  }
})

const saveProfile = async () => {
  savingProfile.value = true
  try {
    await userStore.updatePerson(userStore.user.person_id, personForm.value)
    showSnackbar(['Profile updated.'], 'success')
  } catch (error) {
    const errors = error.response?.data?.errors || ['An unknown error occurred']
    showSnackbar(errors, 'error')
  } finally {
    savingProfile.value = false
  }
}

// Expose for tests
defineExpose({ mode, form_title, est, roles, personForm, loadingProfile, savingProfile, saveProfile })
</script>