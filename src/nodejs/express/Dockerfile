FROM node:22-alpine

# Create non-root user
RUN addgroup -g 1001 -S app && adduser -S app -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R app:app /app
USER app

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["node", "index.js"]
