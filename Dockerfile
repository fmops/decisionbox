ARG BUILDER_IMAGE="cgr.dev/chainguard/wolfi-base:latest"
ARG RUNNER_IMAGE="cgr.dev/chainguard/wolfi-base:latest"

ARG COMMIT=""

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
# erlang 26.2.3 has some issues, see https://github.com/erlang/otp/issues/8238
RUN apk add elixir-1.16 'erlang<26.2.3' 'erlang-dev<26.2.3' git make gcc glibc-dev rust npm nodejs curl

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"
ENV RUSTFLAGS="-C target-feature=-crt-static"
ENV ERL_FLAGS="+JPperf true"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# Make sure image contains node modules referenced in assets/
# https://elixirforum.com/t/how-to-get-daisyui-and-phoenix-to-work/46612/16
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}
ARG COMMIT

RUN apk add ncurses libstdc++

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"
ENV COMMIT=${COMMIT}

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/excision ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

CMD ["/app/bin/server"]
