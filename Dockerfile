FROM crystallang/crystal:0.34.0

RUN apt-get update -qq && apt-get install -y --no-install-recommends libncursesw5-dev libgpm-dev

CMD ["crystal", "--version"]

