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
    imagemagick-dev \
    curl

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

# Install dependencies (including dev deps for asset building)
RUN mix deps.get && \
    mix deps.compile

# Copy source code
COPY . .

# Clean and reinstall dependencies to ensure consistency
RUN mix deps.clean --all && \
    mix deps.get && \
    mix deps.compile

# Install Tailwind CSS via npm to avoid download issues
RUN cd assets && \
    npm install && \
    cd ..

# Build assets with custom Tailwind script to avoid download issues
RUN cd assets && \
    npm run build && \
    cd .. && \
    mix esbuild ai_chat --minify && \
    mix phx.digest

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
    bash \
    wget \
    libstdc++

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
