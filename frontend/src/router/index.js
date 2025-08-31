import { createRouter, createWebHistory } from 'vue-router'
import useUserStore from '../stores/UserStore'

import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import SignUp from '../views/Signup.vue'
import Confirmation from '../views/Confirmation.vue'
import PasswordEdit from '../views/PasswordEdit.vue'
import PasswordReset from '../views/PasswordReset.vue'
import Account from '../views/Account.vue'
import Roles from '../views/Roles.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn) {
        next({ name: 'Dashboard' })
      } else {
        next()
      }
    }
  },
  {
    path: '/signup',
    name: 'Signup',
    component: SignUp,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn) {
        next({ name: 'Dashboard' })
      } else {
        next()
      }
    }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn) {
        next()
      } else {
        next({ name: 'Login' })
      }
    }
  },
  {
    path: '/confirmation',
    name: 'Confirmation',
    component: Confirmation
  },
  {
    path: '/password-reset',
    name: 'PasswordReset',
    component: PasswordReset
  },
  { 
    path: '/password/edit',
    name: 'PasswordEdit',
    component: PasswordEdit
  },
  {
    path: '/account',
    name: 'Account',
    component: Account,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn) {
        next()
      } else {
        next({ name: 'Dashboard' })
      }
    }
  },
  {
    path: '/roles',
    name: 'Roles',
    component: Roles,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn && userStore.hasRole('admin')) {
        next()
      } else {
        next({ name: 'Dashboard' })
      }
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router