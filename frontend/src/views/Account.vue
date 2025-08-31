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
        <span v-if="roles.length">{{roles}}</span>
        <br>
        <br>
        <a @click="mode = 'change_email'">Change Email</a> | <a @click="mode = 'change_password'">Change Password</a>
        </v-card>
      </div>
      <div v-if="mode != 'view'">
        <h2>{{form_title}}</h2>
          <UpdateAccount :mode="mode">
              <template #actions>
                  <a @click="mode = 'view'">Close</a>
              </template>
          </UpdateAccount>
      </div>
    </v-container>
  </template>
  
  <script>
  import { useRouter } from 'vue-router'
  import { inject, computed, ref } from 'vue'
  import useUserStore from '../stores/UserStore'
  import UpdateAccount from './UpdateAccount.vue'
  import _ from 'lodash'
  
  export default {
      components: {
    UpdateAccount   // ✅ register the child component here
  },
    setup() {
      const router = useRouter()
      const showSnackbar = inject('showSnackbar')
      const userStore = useUserStore()
      const mode = ref('view')
  
      const est = computed({
        get() {
          return new Date(userStore.user.created_at).getFullYear()
        },
      });

      const form_title = computed({
        get() {
          return _.startCase(mode.value)
        }
      });

      const roles = computed({
        get() {
          return userStore.user.roles.map(item => item.name).join(', ')
        },
      });
  
  
      return {
        est,
        roles,
        router,
        mode,
        showSnackbar,
        userStore,
        form_title
      }
    }
  }
  </script>