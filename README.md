# DecisionBox

## Getting Started

```sh
docker pull ghcr.io/fmops/decisionbox:latest
docker run \
    --rm \
    -p 4000:4000 \
    -v ./db:/app/db:z \
    -v ./checkpoints:/app/checkpoints:z \
    --env DATABASE_PATH=/app/db/db.sqlite \
    --env SECRET_KEY_BASE=`mix phx.gen.secret` \
    --env PHX_HOST=localhost \
    ghcr.io/fmops/decisionbox:latest \
    bash -c "/app/bin/migrate && /app/bin/server"
```

In a web browser: [http://localhost:4000](http://localhost:4000)


Explanation:

 - Port maps `4000` on the host to `4000` in the container
 - Volume maps `./db` (sqlite DB) and `./checkpoints` (model checkpoints)
 - Runs idempotent migrations and starts server


### Examples

The python examples in `examples/` also use `flake.nix`. To invoke a decision site:

## Developing

Dependencies are managed with `flake.nix` and `nix-direnv`.

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


```sh
python structured_response.py
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## FAQ

EXLA NIF fails to load with SELinux

```sh
execstack -c _build/dev/lib/exla/priv/libexla.so
```

Switching between CPU/GPU

```sh
# export XLA_TARGET=cuda12
export XLA_TARGET=cpu
mix deps.clean xla exla && mix deps.get
```
