// Jest setup file for Vue 3 testing
import * as Vue from 'vue'

// Make Vue globally available for @vue/test-utils
globalThis.Vue = Vue

// Mock import.meta for Vite environment variables
global.import = global.import || {}
global.import.meta = {
  env: {
    VITE_API_BASE_URL: 'http://localhost:3000'
  }
}