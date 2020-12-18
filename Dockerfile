# this container builds the kilt-parachain binary from source files and the runtime library
# pinned the version to avoid build cache invalidation
FROM paritytech/ci-linux:5297d82c-20201107 as builder

WORKDIR /build

# to avoid early cache invalidation, we build only dependencies first. For this we create fresh crates we are going to overwrite.
RUN USER=root cargo init --bin --name=kilt-parachain node
RUN USER=root cargo new --lib --name=kilt-parachain-runtime runtime
RUN USER=root cargo new --lib --name=kilt-parachain-primitives primitives
# overwrite cargo.toml with real files
COPY Cargo.toml Cargo.lock ./
COPY ./node/build.rs ./node/Cargo.toml ./node/
COPY ./runtime/Cargo.toml ./runtime/
COPY ./primitives/Cargo.toml ./primitives/

# build depedencies (and bogus source files)
RUN cargo build --release

# remove bogus build (but keep depedencies)
RUN cargo clean --release -p kilt-parachain-runtime
RUN cargo clean --release -p kilt-parachain-primitives

# copy everything over (cache invalidation will happen here)
COPY . /build
# build source again, dependencies are already built
RUN cargo build --release

# test
RUN cargo test --release

FROM debian:stretch-slim

WORKDIR /runtime

RUN apt-get -y update && \
	apt-get install -y --no-install-recommends \
	openssl \
	curl \
	libssl-dev dnsutils

# cleanup linux dependencies
RUN apt-get autoremove -y
RUN apt-get clean -y
RUN rm -rf /tmp/* /var/tmp/*

RUN mkdir -p /runtime/target/release/
COPY --from=builder /build/target/release/kilt-parachain /usr/local/bin/kilt-parachain

RUN ls -la .

# expose node ports
EXPOSE 30333 9933 9944

ENTRYPOINT [ "/usr/local/bin/kilt-parachain" ]
CMD ["--help"]
