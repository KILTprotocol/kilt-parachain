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

# ===== SECOND STAGE ======

FROM debian:buster-slim
LABEL description="This is the 2nd stage: a very small image where we copy the kilt-parachain binary."

COPY --from=builder /build/target/release/kilt-parachain /usr/local/bin

RUN useradd -m -u 1000 -U -s /bin/sh -d /node node && \
	mkdir -p /node/.local/share/node && \
	chown -R node:node /node/.local && \
	ln -s /node/.local/share/node /data && \
	rm -rf /usr/bin /usr/sbin

COPY --from=builder /build/target/release/wbuild/kilt-parachain-runtime/kilt_parachain_runtime.compact.wasm /node/parachain.wasm

USER node
EXPOSE 30333 9933 9944
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/kilt-parachain"]
CMD ["--help"]
