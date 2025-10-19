import {computed, ref} from 'vue'
import {defineStore} from 'pinia'
import api from '../services/api'
import { trackEvent } from "../services/ahoy.js";

const useUserStore = defineStore("UserStore", () => {
    
    // state initialization with error handling
    const initUser = () => {
        try {
            const stored = localStorage.getItem('user')
            return stored ? JSON.parse(stored) : null
        } catch (e) {
            console.error('Error parsing stored user:', e)
            return null
        }
    }
    
    const user = ref(initUser())
    const bearerToken = ref(localStorage.getItem('bearerToken'))

    // Ensure Authorization header is set on store init (for refresh)
    const setAuthHeader = (token) => {
        if (token) {
            api.defaults.headers.common['Authorization'] = `Bearer ${token}`
        } else {
            delete api.defaults.headers.common['Authorization']
        }
    }

    // Initialize auth header
    setAuthHeader(bearerToken.value)

    // getters
    const isLoggedIn = computed(() => bearerToken.value !== null)

    const hasRole = (roleName) => {
        if (!user.value || !user.value.roles) return false;
        return user.value.roles.map(item => item.name).includes(roleName);
    }

    //actions

    const login = async (data) => {
        const response = await api.post(`/login`, data)
        bearerToken.value = response.data.token
        localStorage.setItem('bearerToken', bearerToken.value)
        user.value = response.data.user
        localStorage.setItem('user', JSON.stringify(user.value))
        // Update auth header for future requests
        setAuthHeader(response.data.token)
        // Track login event with new token
        await trackEvent('logged in', {}, response.data.token)

        return response
    }

    const logout = async () => {
        const token = bearerToken.value
        if (!isLoggedIn.value) {
          return { data: { message: 'Already signed out' } }
        }
        
        try {
          // Track the logout event first while we still have valid auth
          await trackEvent("logged out", {}, token)
          
          // Then try to log out on the server
          const response = await api.delete(`/logout`)
          return response
        } catch (error) {
          console.warn('Logout error:', error)
          return { data: { message: 'Error during logout, but session cleared' } }
        } finally {
          // Always clean up local state
          bearerToken.value = null
          user.value = null
          localStorage.removeItem('bearerToken')
          localStorage.removeItem('user')
          setAuthHeader(null)
        }
    }

    const update = async (data) => {
        const response = await api.patch(`/users/${user.value.id}`, data)
        user.value = response.data.user
        localStorage.setItem('user', JSON.stringify(user.value))
        return response 
    }
    
    
    

    return {user, bearerToken, isLoggedIn, login, logout, update, hasRole}
})

export default useUserStore