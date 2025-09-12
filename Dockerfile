# Use the official Elixir image as base
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm \
    python3 \
    py3-pip \
    imagemagick \
    imagemagick-dev

# Set environment variables
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey

# Create app directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy source code
COPY . .

# Build assets
RUN mix assets.deploy

# Compile the application
RUN mix compile

# Build the release
RUN mix release

# Production stage
FROM alpine:latest AS runner

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    imagemagick \
    bash

# Create non-root user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

# Set working directory
WORKDIR /app

# Copy the release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/ai_chat ./

# Switch to non-root user
USER app

# Expose port
EXPOSE 4000

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=4000
ENV PHX_SERVER=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4000/ || exit 1

# Start the application
CMD ["./bin/ai_chat", "start"]
