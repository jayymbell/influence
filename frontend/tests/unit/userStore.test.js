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

test('logout calls trackEvent and api and clears state', async () => {
  mockApi.delete.mockResolvedValue({ data: { message: 'ok' } })
  const store = useUserStore()
  // prime state
  store.bearerToken = 'tok'
  store.user = { id: 2 }
  localStorage.setItem('bearerToken', 'tok')
  localStorage.setItem('user', JSON.stringify({ id: 2 }))

  const res = await store.logout()

  expect(trackEvent).toHaveBeenCalledWith('logged out', {}, 'tok')
  expect(mockApi.delete).toHaveBeenCalledWith('/logout')
  expect(store.bearerToken).toBeNull()
  expect(store.user).toBeNull()
  expect(localStorage.getItem('bearerToken')).toBeNull()
  expect(localStorage.getItem('user')).toBeNull()
  expect(mockApi.defaults.headers.common['Authorization']).toBeUndefined()
})

test('update replaces user and persists', async () => {
  mockApi.patch.mockResolvedValue({ data: { user: { id: 5, name: 'Updated' } } })
  const store = useUserStore()
  const res = await store.update({ name: 'Updated' })
  expect(mockApi.patch).toHaveBeenCalledWith('/signup', { name: 'Updated' })
  expect(store.user).toEqual({ id: 5, name: 'Updated' })
  expect(localStorage.getItem('user')).toBe(JSON.stringify({ id: 5, name: 'Updated' }))
})
