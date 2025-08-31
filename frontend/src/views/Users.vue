<template>
    <v-container>
        <h1>Users</h1>
        <div v-if="!user" style="width: 500px;">
                    <v-text-field
            v-model="searchEmail"
            label="Search by Email"
            @input="filterUsers"
            clearable
        />
            <v-card v-for="user in filteredUsers" :key="user.id"  class="pa-3 mt-3" outlined>
                <v-row>
                    <v-col>
                        {{ user.email }} 
                    </v-col>
                    <v-col>
                        <a style="float: right; margin-right: 10px;" @click="fetchUser(user)">Open</a>
                    </v-col>
                </v-row>
            </v-card>
        </div>
        <div v-else style="width: 500px;">
            <h2>{{ user.email }}</h2>
            <h3>Roles</h3>
            <v-card v-for="role in user.roles" :key="role.id" class="pa-3 mt-3" outlined>
                <v-row>
                    <v-col>
                        {{ role.name }}
                    </v-col>
                </v-row>
            </v-card>
            <span v-if="!user.roles.length">
                None found.
            </span>
            <br/>
            <h3>Activity</h3>
            <div v-for="event in events.slice(0,10)" :key="event.id">
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
import { onMounted, ref } from 'vue'
import api from '../services/api.js'

export default {
  setup() {
    const users = ref('')
    const user = ref('')
    const events = ref('')
    const searchEmail = ref('')
    const filteredUsers = ref('')

    const fetchUsers = async() => {
        const response = await api.get('/users');
        users.value  = response.data.users
        filteredUsers.value = response.data.users
    }

    const fetchUser = async(u) => {
        const response = await api.get('/users/'+u.id);
        user.value  = response.data.user

        fetchEvents(u)
    }

    const filterUsers = () => {
      const email = searchEmail.value.toLowerCase();
      filteredUsers.value = users.value.filter(user =>
        user.email.toLowerCase().includes(email)
      );
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

    onMounted(() => {
      fetchUsers()
    })
    return {users, user, searchEmail, filteredUsers, fetchUser, filterUsers};
  }
}
</script>