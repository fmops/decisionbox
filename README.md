# DecisionBox

Thanks for using DecisionBox!  Extra kudos if you could contribute back to the project, or provide your feedback here:
https://github.com/fmops/decisionbox/discussions

If you want to dive right in to SDK install and config, skip to "Getting Started" below.

## Introduction - DecisionBox SDK Overview

The purpose of this product is to allow you to radically improve your LLM app so it gets smarter with more data

The Pain Point 

Building high-quality LLM applications often hinges on the accuracy of critical decision points within your app. While OpenAI function calls may suffice for quick prototypes, achieving production-level accuracy often necessitates laborious prompt engineering, which yields diminishing returns. Additionally, not every development team has the luxury of a dedicated data science team to support every app they build.

The DecisionBox Solution
DecisionBox empowers developers to make high-accuracy decisions within their LLM apps that continuously improve with more data. It streamlines the data science process into a simple API, allowing developers to achieve business-critical outcomes without extensive data science expertise.
Key Benefits:
•	High Accuracy Decisions: Make critical decisions within your app with confidence, knowing they're backed by a robust data science process.
•	Continuous Improvement: As your app gathers more data, DecisionBox models learn and adapt, further enhancing decision accuracy.
•	Ongoing Accuracy Metrics: Track and monitor decision accuracy to ensure your app meets your business objectives.
•	Resource Efficiency: Simplify the data science process with an easy-to-use API, eliminating the need for extensive data science resources.

High Level Developer Journey
1.	Install the DecisionBox SDK.
2.	Replace Existing Code: Replace code using OpenAI function calls or structured outputs with simple API calls to DecisionBox wherever you have a critical decision in your app, for which you need accuracy analytics, and improvements over time.  Initially we recommend you just instrument your existing decisions from your LLM service, so that you capture a baseline of decision quality, before calling your new Classifer.
3.	Create Task-Specific Model: DecisionBox automatically creates small, task-specific models for each key decision point within your app.
4.	Efficiently label response data to establish a baseline for accuracy.
5.	Replace function calls, invoke your Classifer for each critical decision.
6.	As the app is used, label further responses using the DecisionBox guided interface.
7.	Now you can train your DecisionBox models and promote them to production to see immediate improvements in decision accuracy.
3.	Share Metrics: Share accuracy metrics with stakeholders to demonstrate the impact of DecisionBox on your app's performance.

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
