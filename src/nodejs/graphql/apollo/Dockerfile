FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --production

COPY src/ ./src/

RUN addgroup -g 1001 -S app && adduser -u 1001 -S app -G app

EXPOSE 3000

USER app

CMD ["node", "src/index.js"]
