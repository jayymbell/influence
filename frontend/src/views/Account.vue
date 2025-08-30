<template>
    <v-container>
      <div v-if="mode == 'view'">
        <h1>Account</h1>
        {{ userStore.user.email }}
        <br>
        member since {{ est }}
        <br>
        <span v-if="roles.length">{{roles}}</span>
        <br>
        <br>
        <a @click="mode = 'change_email'">change email</a>
        <br>
        <a @click="mode = 'change_password'">change password</a>
      </div>
      <div v-if="mode != 'view'">
        <h1>Account</h1>
        <h2>{{form_title}}</h2>
          <UpdateAccount :mode="mode">
              <template #actions>
                  <a @click="mode = 'view'">Cancel</a>
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
          return userStore.user.roles.join(', ')
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