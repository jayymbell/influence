/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'

// Mock the API and tracking services
jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  post: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn().mockResolvedValue({}) }))

const mockApi = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

import useUserStore from '../../src/stores/UserStore'

beforeEach(() => {
  localStorage.clear()
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

test('initializes with no user or token', () => {
  const store = useUserStore()
  expect(store.user).toBeNull()
  expect(store.bearerToken).toBeNull()
  expect(store.isLoggedIn).toBe(false)
})

test('login stores token and user and sets auth header', async () => {
  mockApi.post.mockResolvedValue({ data: { token: 'abc123', data: { id: 1, roles: [{ name: 'admin' }] } } })
  const store = useUserStore()

  const res = await store.login({ username: 'u', password: 'p' })

  expect(mockApi.post).toHaveBeenCalledWith('/login', { username: 'u', password: 'p' })
  expect(store.bearerToken).toBe('abc123')
  expect(localStorage.getItem('bearerToken')).toBe('abc123')
  expect(store.user).toEqual({ id: 1, roles: [{ name: 'admin' }] })
  expect(localStorage.getItem('user')).toBe(JSON.stringify({ id: 1, roles: [{ name: 'admin' }] }))
  expect(mockApi.defaults.headers.common['Authorization']).toBe('Bearer abc123')
  expect(store.hasRole('admin')).toBe(true)
})

test('login without user data in response logs error', async () => {
  mockApi.post.mockResolvedValue({ data: { token: 'abc123' } })
  const store = useUserStore()
  jest.spyOn(console, 'error').mockImplementation()

  await store.login({ username: 'u', password: 'p' })

  expect(console.error).toHaveBeenCalledWith('No user data received in login response:', expect.any(Object))
})

test('login without token in response logs error', async () => {
  mockApi.post.mockResolvedValue({ data: {} })
  const store = useUserStore()
  jest.spyOn(console, 'error').mockImplementation()

  await store.login({ username: 'u', password: 'p' })

  expect(console.error).toHaveBeenCalledWith('No token received in login response')
})

test('hasRole returns false when user is null', () => {
  const store = useUserStore()
  expect(store.hasRole('admin')).toBe(false)
})

test('hasRole returns false when user has no roles', () => {
  const store = useUserStore()
  store.user = { id: 1, roles: [] }
  expect(store.hasRole('admin')).toBe(false)
})

test('hasRole returns true for matching role', () => {
  const store = useUserStore()
  store.user = { id: 1, roles: [{ name: 'user' }, { name: 'admin' }] }
  expect(store.hasRole('admin')).toBe(true)
})

test('logout when already logged out returns message', async () => {
  const store = useUserStore()
  store.bearerToken = null
  store.user = null

  const res = await store.logout()

  expect(res.data.message).toBe('Already signed out')
})

test('logout clears auth header', async () => {
  mockApi.delete.mockResolvedValue({ data: { message: 'ok' } })
  const store = useUserStore()
  store.bearerToken = 'tok'
  store.user = { id: 2 }
  mockApi.defaults.headers.common['Authorization'] = 'Bearer tok'

  await store.logout()

  expect(mockApi.defaults.headers.common['Authorization']).toBeUndefined()
})

test('logout handles api error gracefully', async () => {
  mockApi.delete.mockRejectedValue(new Error('Network error'))
  const store = useUserStore()
  store.bearerToken = 'tok'
  store.user = { id: 2 }
  jest.spyOn(console, 'warn').mockImplementation()

  const res = await store.logout()

  expect(console.warn).toHaveBeenCalledWith('Logout error:', expect.any(Error))
  expect(res.data.message).toBe('Error during logout, but session cleared')
  expect(store.bearerToken).toBeNull()
  expect(store.user).toBeNull()
})

test('update replaces user and persists', async () => {
  mockApi.patch.mockResolvedValue({ data: { user: { id: 5, name: 'Updated' } } })
  const store = useUserStore()
  const res = await store.update({ name: 'Updated' })
  expect(mockApi.patch).toHaveBeenCalledWith('/signup', { name: 'Updated' })
  expect(store.user).toEqual({ id: 5, name: 'Updated' })
  expect(localStorage.getItem('user')).toBe(JSON.stringify({ id: 5, name: 'Updated' }))
})

test('restores user from localStorage on init', () => {
  const userData = { id: 10, name: 'Persisted User', roles: [{ name: 'user' }] }
  localStorage.setItem('user', JSON.stringify(userData))
  localStorage.setItem('bearerToken', 'persisted-token')
  
  setActivePinia(createPinia())
  const store = useUserStore()

  expect(store.user).toEqual(userData)
  expect(store.bearerToken).toBe('persisted-token')
  expect(store.isLoggedIn).toBe(true)
})

test('handles corrupted localStorage data gracefully', () => {
  localStorage.setItem('user', 'not valid json')
  jest.spyOn(console, 'error').mockImplementation()
  
  setActivePinia(createPinia())
  const store = useUserStore()

  expect(console.error).toHaveBeenCalledWith('Error parsing stored user:', expect.any(Error))
  expect(store.user).toBeNull()
  expect(localStorage.getItem('user')).toBeNull()
})
