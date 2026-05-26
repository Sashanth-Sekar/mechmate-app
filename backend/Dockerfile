FROM node:20-alpine AS development

WORKDIR /usr/src/app

# Install build dependencies required by native modules (better-sqlite3, etc.)
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

RUN npm run build

FROM node:20-alpine AS production

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --legacy-peer-deps --omit=dev

COPY --from=development /usr/src/app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main"]
