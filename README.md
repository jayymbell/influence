# Rails Vue Project Template
Follow the instructions below to build a brand new web app using Ruby on Rails as a back-end and Vue.js as a front-end. 

1. Build containers

    a) `docker-compose build`

2. Generate rails backend

    a) `cd backend`

    b)`docker-compose run backend rails new . --api --database=postgresql`

    c) replace 'backend' with project name

    d) update postgresql host in database.yml

 3. Generate vue frontend
 
    a) `cd frontend`

    c) `docker-compose run frontend yarn create vite . --template vue`