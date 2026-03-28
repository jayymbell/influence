FROM node:25.8-bullseye

# use /frontend as working dir
WORKDIR /frontend

# copy package manifests and install dependencies
COPY package*.json ./
RUN yarn install

# copy source
COPY . .

# ensure Playwright browsers are available (image already includes them, but harmless)
# Install Playwright browsers and required dependencies
RUN npx playwright install --with-deps || true

CMD [ "yarn", "dev", "--host", "0.0.0.0" ]