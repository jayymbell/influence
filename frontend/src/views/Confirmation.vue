<template>
  <v-container class="fill-height align-center justify-center">
    <v-btn @click="confirmUser">Confirm Email</v-btn>
  </v-container>
</template>
  
  <script>
  import { useRouter, useRoute } from 'vue-router'
  import { inject } from 'vue'
  import api from '../services/api'
  
  export default {
    setup() {
      const router = useRouter()
      const route = useRoute()
      const showSnackbar = inject('showSnackbar')
      return { router, route, showSnackbar }
    },
    methods: {
      async confirmUser() {
        const confirmation_token = this.route.query.confirmation_token;
        if (confirmation_token) {
          try {
            const response = await api.get(`/confirmation`, {
                params: {
                    confirmation_token: confirmation_token  
                }
            })
            this.showSnackbar([response.data.status.message], 'success')
            this.router.push({ name: 'Login' })
          } catch (error) {
            const errors = []
            switch(error.response.data.status) {
              case 406:
                this.showSnackbar(['Invalid token.'], 'error')
                break
              default:
                if (error.response.data.errors) {
                  for (const i in error.response.data.errors) {
                    errors.push(error.response.data.errors[i])
                  }
                }
                else if(error.response.data.error) {
                  errors.push(error.response.data.error)
                }
                else {
                  errors.push(error.response.data.error || 'An unknown error occurred')
                }
                this.showSnackbar(errors, 'error')
            }
          }
        }
        else {
          this.showSnackbar(['No token found'], 'error')
        }
      }
    }
  };
  </script>