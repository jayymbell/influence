<template>
    <v-container>
        <h1>Users</h1>
        <div v-if="!user" style="width: 500px;">
            <v-card v-for="user in users" :key="user.id"  class="pa-3 mt-3" outlined>
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

    const fetchUsers = async() => {
        const response = await api.get('/users');
        users.value  = response.data.users
    }

    const fetchUser = async(u) => {
        const response = await api.get('/users/'+u.id);
        user.value  = response.data.user
    }

    onMounted(() => {
      fetchUsers()
    })
    return {users, user, fetchUser};
  }
}
</script>