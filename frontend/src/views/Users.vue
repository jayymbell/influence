<template>
    <v-container>
        <h1>Users</h1>
        <div v-if="!user">
            <v-row>
                <v-col cols="8">
            <v-text-field
                v-model="searchEmail"
                label="Search by Email"
                @input="filterUsers"
                clearable
            />
                </v-col>
                <v-col>
                                <v-switch
                v-model="showActive"
                @input="filterUsers"
                :label="showActive ? 'Active' : 'Inactive'"
            />
                </v-col>
            </v-row>
            <v-divider class="my-4"></v-divider>
            <template v-if="loading">
              <v-skeleton-loader v-for="n in 4" :key="n" type="list-item" class="mb-2" />
            </template>
            <template v-else>
            <v-card v-for="user in (filteredUsers || [])" :key="user.id"  class="pa-3 mt-3" outlined>
                <v-row>
                    <v-col>
                        {{ user.email }} 
                    </v-col>
                    <v-col cols="auto">
                        <v-btn variant="text" size="small" @click="fetchUser(user)">Open</v-btn>
                        <v-btn v-if="!user.discarded_at" variant="text" size="small" color="error" @click="deactivateUser(user)">Deactivate</v-btn>
                        <v-btn v-else variant="text" size="small" color="success" @click="reactivateUser(user)">Reactivate</v-btn>
                    </v-col>
                </v-row>
            </v-card>
            </template>
            <span v-if="!loading && (!filteredUsers || !filteredUsers.length)">
                None found.
            </span>
        </div>
        <div v-else>
            <v-chip
                v-if="user.discarded_at"
                label
                style="float: right;"
            >Inactive</v-chip>
            <h2>{{ user.email }}</h2>
            member since {{ est }}
            <h3>Roles</h3>
            <v-card v-for="role in (user.roles || [])" :key="role.id" class="pa-3 mt-3" outlined>
                <v-row>
                    <v-col>
                        {{ role.name }}
                    </v-col>
                    <v-col cols="auto">
                        <v-btn variant="text" size="small" color="error" @click="deleteRole(role)">Remove</v-btn>
                    </v-col>
                </v-row>
            </v-card>
            <span v-if="!(user.roles || []).length">
                None found.
            </span>
            <br/>
            <h3>Activity</h3>
            <div v-for="event in (events || []).slice(0,10)" :key="event.id">
                <v-divider class="my-2"></v-divider>
                <v-row>
                    <v-col>
                        {{ new Date(event.time).toLocaleString() }}
                    </v-col>
                    <v-col>
                        {{ event.name }}
                    </v-col>
                </v-row>
            </div>
            <br/>
            <br/>
            <a style="margin-right: 10px;" @click="user = ''">Close</a>
        </div>
    </v-container>
</template>
<script>
import { onMounted, ref, inject, computed } from 'vue'
import api from '../services/api.js'
import { trackEvent } from "../services/ahoy.js";

export default {
  setup() {
    const users = ref([])
    const user = ref('')
    const events = ref([])
    const searchEmail = ref('')
    const filteredUsers = ref([])
    const showActive = ref(true)
    const loading = ref(false)
    const showSnackbar = inject('showSnackbar')

    const est = computed({
        get() {
          return new Date(user.value.created_at).getFullYear()
        },
      });

    const fetchUsers = async() => {
        loading.value = true
        try {
        const response = await api.get('/users');
        users.value  = response.data.users
        filteredUsers.value = response.data.users
        filterUsers()
        } finally {
          loading.value = false
        }
    }

    const fetchUser = async(u) => {
        const response = await api.get('/users/'+u.id);
        user.value  = response.data.user

        fetchEvents(u)
    }

    const filterUsers = () => {
      const email = searchEmail.value.toLowerCase();
      // Defensive check to ensure users.value is an array before filtering
      if (!Array.isArray(users.value)) return;
      
      filteredUsers.value = users.value.filter(user => {
        const matchesEmail = user.email.toLowerCase().includes(email);
        const isActive = showActive.value ? !user.discarded_at : !!user.discarded_at;
        return matchesEmail && isActive;
      });
    }

    const fetchEvents = async(u) => {
        try{
            const response = await api.get('users/events', { params: { user_id: u.id } });
            events.value  = response.data.events
        }
        catch(error){
            const e = error.response.data.errors || ['An unknown error occurred']
            showSnackbar(e, 'error')
        }
    }

    const deactivateUser = async(u) => {
        try{
      if (confirm(`Are you sure you want to deactivate user ${u.email}?`)) {
        const response = await api.delete('/users/'+u.id);
        trackEvent("deactivated user", {user_id: u.id});
        showSnackbar(['User deactivated'], 'success')
        fetchUsers()
        user.value = ''
      }
    }
    catch(error){
        const e = error.response.data.errors || ['An unknown error occurred']
        showSnackbar(e, 'error')
    }
    
}
    const reactivateUser = async(u) => {
        try{
        const response = await api.patch('/users/'+u.id, {user: {discarded_at: null}});
        trackEvent("reactivated user", {user_id: u.id});
        showSnackbar(['User reactivated'], 'success')
        fetchUsers()
    }
    catch(error){
        const e = error.response.data.errors || ['An unknown error occurred']
        showSnackbar(e, 'error')
    }
}

const deleteRole = async(r) => {
        try{
            const roleIds = user.value.roles.map(item => item.id)
            const filteredRoleIds = roleIds.filter(id => id !== r.id);
            await api.patch('/users/'+user.value.id, { user: {role_ids: filteredRoleIds }});
            trackEvent("removed user role", {user_id: user.value.id, role_id: r.id});
            showSnackbar(['User role removed'], 'success')
            fetchUser(user.value)
    }
    catch(error){
        const e = error.response.data.errors || ['An unknown error occurred']
        showSnackbar(e, 'error')
    }
}


    onMounted(() => {
      fetchUsers()
    })
    return {users, user, searchEmail, filteredUsers, fetchUser, filterUsers, deactivateUser, est, events, fetchEvents, showActive, reactivateUser, deleteRole, loading};
  }
}
</script>