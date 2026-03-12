<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import useUserStore from '../stores/UserStore'
import useSidebarStore from '../stores/SidebarStore'

const router = useRouter()
const userStore = useUserStore()
const sidebarStore = useSidebarStore()

const isLoggedIn = computed(() => userStore.isLoggedIn)
const isAdmin = computed(() => userStore.hasRole('admin'))

const menuItems = computed(() => {
  const items = [
    { title: 'Dashboard', icon: 'mdi-view-dashboard', to: '/', show: true },
    { title: 'General Assistant', icon: 'mdi-forum-outline', to: '/conversations', show: isLoggedIn.value },
    { title: 'Account', icon: 'mdi-account', to: '/account', show: isLoggedIn.value },
  ]

  const adminItems = [
    { divider: true, show: isAdmin.value },
    { subtitle: 'Admin', show: isAdmin.value },
    { title: 'Roles', icon: 'mdi-shield-account', to: '/roles', show: isAdmin.value },
    { title: 'Users', icon: 'mdi-account-group', to: '/users', show: isAdmin.value },
  ]

  return [...items, ...adminItems].filter(item => item.show)
})

const navigate = (to) => {
  router.push(to)
}
</script>

<template>
  <v-navigation-drawer
    v-model="sidebarStore.isOpen"
    :width="256"
    theme="dark"
    elevation="2"
  >
    <v-list density="compact" nav>
      <template v-for="(item, i) in menuItems" :key="i">
        <v-divider v-if="item.divider" class="my-2" />
        <v-list-subheader v-else-if="item.subtitle">
          {{ item.subtitle }}
        </v-list-subheader>
        <v-list-item
          v-else
          :prepend-icon="item.icon"
          :title="item.title"
          :to="item.to"
          :active="$route.path === item.to"
          @click="navigate(item.to)"
          rounded="lg"
          class="mx-2"
        />
      </template>
    </v-list>
  </v-navigation-drawer>
</template>
