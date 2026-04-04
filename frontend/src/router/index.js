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
import Users from '../views/Users.vue'
import Conversations from '../views/Conversations.vue'
import People from '../views/People.vue'

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
    path: '/conversations',
    name: 'Conversations',
    component: Conversations,
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
  },
  {
    path: '/users',
    name: 'Users',
    component: Users,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn && userStore.hasRole('admin')) {
        next()
      } else {
        next({ name: 'Dashboard' })
      }
    }
  },
  {
    path: '/people',
    name: 'People',
    component: People,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn && (userStore.hasRole('admin') || userStore.hasRole('staff'))) {
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