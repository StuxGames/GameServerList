# Use cargo chef to speed up builds
FROM lukemathwalker/cargo-chef:0.1.62-rust-1.75-slim-bullseye AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release

# We do not need the Rust toolchain to run the binary!
FROM debian:bullseye-slim AS runtime
WORKDIR /app

# Install curl for healthcheck
RUN apt update && apt install -y curl

HEALTHCHECK --interval=1m --timeout=10s --retries=3 --start-period=1m \
    CMD curl --fail localhost:3000/api/list/healthcheck || exit 1

COPY --from=builder /app/target/release/gameserverlist /usr/local/bin
ENTRYPOINT ["/usr/local/bin/gameserverlist"]
