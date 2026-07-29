FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --production

COPY src/ ./src/

RUN addgroup -g 1001 app && adduser -u 1001 -G app -s /bin/sh -D app

EXPOSE 3000

USER app

CMD ["node", "src/server.js"]
