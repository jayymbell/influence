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
import AccountSetup from '../views/AccountSetup.vue'
import InviteAccept from '../views/InviteAccept.vue'

// Routes that are exempt from the account-setup redirect
const SETUP_EXEMPT = ['Login', 'Signup', 'Confirmation', 'PasswordReset', 'PasswordEdit', 'AccountSetup', 'InviteAccept']

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
  },
  {
    path: '/account-setup',
    name: 'AccountSetup',
    component: AccountSetup,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (!userStore.isLoggedIn) return next({ name: 'Login' })
      // Redirect away if they already have a person
      if (userStore.hasPerson) return next({ name: 'Dashboard' })
      next()
    }
  },
  {
    path: '/invite/accept',
    name: 'InviteAccept',
    component: InviteAccept,
    beforeEnter: (to, from, next) => {
      const userStore = useUserStore()
      if (userStore.isLoggedIn) return next({ name: 'Dashboard' })
      next()
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Global guard: block non-admin/staff users who haven't completed profile setup
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()

  if (!userStore.isLoggedIn) return next()
  if (SETUP_EXEMPT.includes(to.name)) return next()

  const isAdminOrStaff = userStore.hasRole('admin') || userStore.hasRole('staff')
  if (!isAdminOrStaff && !userStore.isSystemUser && !userStore.hasPerson) {
    return next({ name: 'AccountSetup' })
  }

  next()
})

export default router