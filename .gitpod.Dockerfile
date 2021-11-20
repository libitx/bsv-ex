FROM gitpod/workspace-full:latest
ARG DEBIAN_FRONTEND=noninteractive

# Install erlang & elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    sudo dpkg -i erlang-solutions_2.0_all.deb
RUN sudo apt-get update -q && \
    sudo apt-get install -yq erlang-base erlang-dev erlang-parsetools elixir
RUN mix local.hex --force && \
    mix local.rebar --force

# Serve docs
ENV NGINX_DOCROOT_IN_REPO="doc"