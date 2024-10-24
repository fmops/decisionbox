# DecisionBox

<a href="https://www.producthunt.com/posts/decisionbox-sdk?embed=true&utm_source=badge-featured&utm_medium=badge&utm_souce=badge-decisionbox&#0045;sdk" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=490709&theme=light" alt="DecisionBox&#0032;SDK - Improve&#0032;your&#0032;LLM&#0045;based&#0032;app&#0032;with&#0032;smarter&#0032;decisions&#0032;using&#0032;ML | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>

Thanks for trying DecisionBox!  Extra kudos if you could contribute back to the project, or provide your feedback here:
https://github.com/fmops/decisionbox/discussions

If you want to dive right in to SDK install and config, skip to [Getting Started](#getting-started) below.

Looking for spcification of RESTful APIs?  See https://decisionbox.blueteam.ai/swaggerui

If you'd like to see a quick video of the 'why' of the product, or send it to a friend, please check out:
https://youtu.be/ErulvNvwKHs

## Introduction - DecisionBox SDK Overview

The purpose of this product is to allow you to radically improve your LLM app so it gets smarter with more data.

**The Pain Point**

Building high-quality LLM applications often hinges on the accuracy of critical decision points within your app. While OpenAI function calls may suffice for quick prototypes, achieving production-level accuracy often necessitates laborious prompt engineering, which yields diminishing returns. Additionally, not every development team has the luxury of a dedicated data science team to support every app they build.  So we set out to see if we could simplify setting up a robust Machine Learning environment quickly.

**The DecisionBox SDK Success Metric**

We're hoping that DecisionBox enables you to demonstrate that your app is making high-accuracy decisions within an LLM-based app, and you have evidence to demonstrate that it's continuously improving with more data.  The SDK is meant to streamline the data science process into a simple API, so that extensive data science expertise is not required.

### Quick Walk-Through

1.	Install the DecisionBox SDK and create your first Decision site.  You'll be asked to give this site a name, and a default 'classifier' will be created for you, called "passthrough."   This is actually a passthrough to your hosted LLM provider, so you'll let your app run and collect some data using this method, before replacing this line of code with a local classifier.  The difference is that all generated responses will recorded, so you can label them, and this will reveal your baseline accuracy to improve upon.
2.	Under your Decision Site, create a new Classifier with the appropriate outputs (choices).  You'll give this classifier a name and make this "active" rather than the default passthrough classifier. 
3.	Replace Existing Code: Replace the code in your app which is currently using OpenAI function calls or structured outputs with the DecisionBox API call to your decision site, such that the currently active classifier will be invoked.
4.	As your app runs, you'll be collecting responses associated with the invoked classifier.  These are recorded 'decisions' which you can label, if you find they can be improved.   Remember, you don't need to label a ton of data to see large improvements in accuracy!
5.	With at least 5-10 decisions labeled, you'll have the opportunity to "train" your task-specific classifier, and promote it to production.
6.	After letting the app run a bit more with the newly promoted classifier, you should see improvements in accuracy.  You may want to share these accuracy metrics with business stakeholders to demonstrate that your app is getting smarter with more data.


## Getting Started

Using docker:

```sh
export SECRET_KEY_BASE=$(openssl rand -hex 32)
docker pull ghcr.io/fmops/decisionbox:latest
docker run \
    --rm \
    -p 4000:4000 \
    --env DATABASE_PATH=/app/db/db.sqlite \
    --env SECRET_KEY_BASE=$SECRET_KEY_BASE \
    --env PHX_HOST=localhost \
    ghcr.io/fmops/decisionbox:latest \
    sh -c "/app/bin/migrate && /app/bin/server"
```

In a web browser: [http://localhost:4000](http://localhost:4000)


Explanation:

 - Port maps `4000` on the host to `4000` in the container
 - Volume maps `./db` (sqlite DB) and `./checkpoints` (model checkpoints)
 - Runs idempotent migrations and starts server

### Submitting data and generating decisions

The python examples in `examples/` show how you can invoke a decision site and submit data.

## Developing

Dependencies are managed with `flake.nix` and `nix-direnv`.

Set environment variables in `.envrc`. See `.envrc.example` for what variables to set.

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * Run `mix run priv/repo/seeds.exs` to seed some fixture data in order to kickstart development

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


### FAQ

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

Ensure db directory is writable so that you can persist data created when running the app via docker

```sh
sudo chown your-user:your-user db
chmod 777 db
```
