# ------------------------------------------------------------------------------
# Development image
# ------------------------------------------------------------------------------

# Create the container from the alpine linux image
FROM node:10.16.3-alpine

RUN apk add --no-cache build-base \
    yarn python g++ make libtool autoconf automake

WORKDIR /app 

COPY Makefile .

COPY package.json ./
COPY yarn.lock ./

RUN yarn install
RUN npm install -g npm-cli-login

COPY . .
