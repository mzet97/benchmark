FROM denoland/deno:2.0

# Create non-root user
RUN addgroup -g 1001 -S app && adduser -S app -u 1001

WORKDIR /app

# Copy application code
COPY server.ts .

# Change ownership to non-root user
RUN chown -R app:app /app
USER app

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["deno", "run", "--allow-net", "--allow-env", "server.ts"]
