FROM elixir:1.19.4-otp-28 AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
  build-essential git python3 curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config/config.exs config/prod.exs config/

RUN mix deps.compile
RUN mix assets.setup

# Copying the rest of the source
COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.deploy
RUN mix compile

# Copy release overlay script
COPY rel rel

RUN mix release

FROM debian:trixie-slim AS runner

# Install runtime dependencies
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

ENV MIX_ENV=prod
ENV PHX_SERVER=true

COPY --from=builder /app/_build/prod/rel/cipher ./

RUN chmod +x /app/bin/server

EXPOSE 4000

CMD ["/app/bin/server"]
