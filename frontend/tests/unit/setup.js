// Mock import.meta for Jest
global.importMeta = { env: { VITE_API_BASE_URL: 'http://localhost:3000' } }
Object.defineProperty(global, 'import.meta', {
  value: global.importMeta
})

import { config } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'

// Create router factory function using real route structure but with mock components for testing
export const createTestRouter = () => {
  const routes = [
    { path: '/login', name: 'Login', component: { template: '<div>Login</div>' } },
    { path: '/signup', name: 'Signup', component: { template: '<div>Signup</div>' } },
    { path: '/', name: 'Dashboard', component: { template: '<div>Dashboard</div>' } },
    { path: '/confirmation', name: 'Confirmation', component: { template: '<div>Confirmation</div>' } },
    { path: '/password-reset', name: 'PasswordReset', component: { template: '<div>PasswordReset</div>' } },
    { path: '/password/edit', name: 'PasswordEdit', component: { template: '<div>PasswordEdit</div>' } },
    { path: '/account', name: 'Account', component: { template: '<div>Account</div>' } },
    { path: '/roles', name: 'Roles', component: { template: '<div>Roles</div>' } },
    { path: '/users', name: 'Users', component: { template: '<div>Users</div>' } }
  ]

  return createRouter({
    history: createWebHistory(),
    routes
  })
}

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // Deprecated
    removeListener: jest.fn(), // Deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

// Mock ResizeObserver
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}))

// Global Vue component stubs for Vuetify
config.global.stubs = {
  'v-container': { template: '<div class="v-container"><slot /></div>' },
  'v-form': { template: '<form><slot /></form>' },
  'v-text-field': { 
    template: '<input :type="type" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
    props: ['modelValue', 'type', 'label', 'required', 'clearable']
  },
  'v-row': { template: '<div class="v-row"><slot /></div>' },
  'v-col': { template: '<div class="v-col"><slot /></div>' },
  'v-btn': { template: '<button :type="type"><slot /></button>', props: ['type', 'block'] },
  'v-card': { template: '<div class="v-card"><slot /></div>' },
  'v-chip': { template: '<span class="v-chip"><slot /></span>' },
  'v-divider': { template: '<hr class="v-divider" />' },
  'v-switch': { 
    template: '<input type="checkbox" :checked="modelValue" @change="$emit(\"update:modelValue\", $event.target.checked)" />',
    props: ['modelValue', 'label']
  },
  'v-dialog': { template: '<div v-if="modelValue" class="v-dialog"><slot /></div>', props: ['modelValue'] },
  'v-list': { template: '<ul class="v-list"><slot /></ul>' },
  'v-list-item': { template: '<li class="v-list-item"><slot /></li>' },
  'v-list-item-title': { template: '<div class="v-list-item-title"><slot /></div>' }
}

// Set up global plugins and provides
// (Router will be set up individually in each test for proper isolation)