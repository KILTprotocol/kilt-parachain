![](https://user-images.githubusercontent.com/1248214/57789522-600fcc00-7739-11e9-86d9-73d7032f40fc.png) <img src="https://www.parity.io/assets/img/built-on-substrate-badge.svg" height=180/>

<!-- [![Build and Test](https://github.com/KILTprotocol/kilt-parachain/workflows/Build%20and%20Test/badge.svg)](https://github.com/KILTprotocol/kilt-parachain/actions) -->

# KILT Parachain <!-- omit in toc -->

The KILT parachain collators use Parity Substrate as the underlying blockchain
technology stack extended with our DID, CType, Attestation and hierarchical Trust Modules.

- [1. How to use/test locally](#1-how-to-usetest-locally)
  - [1.1 Supported Polkadot dependencies](#11-supported-polkadot-dependencies)
  - [1.2. How to use](#12-how-to-use)
  - [1.3. Relay Chain: Polkadot](#13-relay-chain-polkadot)
    - [1.3.1. Start Alice's Node](#131-start-alices-node)
    - [1.3.2. Start Bob's Node](#132-start-bobs-node)
  - [1.4. KILT Collator](#14-kilt-collator)
    - [1.4.1. Obtain WASM Validation Function](#141-obtain-wasm-validation-function)
    - [1.4.2. Start Collator Node](#142-start-collator-node)
    - [1.4.3. Obtain Genesis Head](#143-obtain-genesis-head)
    - [1.4.4. Register parachain in Apps](#144-register-parachain-in-apps)
  - [1.5 Troubleshoot](#15-troubleshoot)
    - [1.5.1 Parachain is stuck on #1](#151-parachain-is-stuck-on-1)
    - [1.5.2 Polkadot Apps Extrinsics Error](#152-polkadot-apps-extrinsics-error)
- [2. Node Modules functionalities](#2-node-modules-functionalities)
  - [2.1. DID Module](#21-did-module)
    - [2.1.1. Add](#211-add)
    - [2.1.2. CRUD](#212-crud)
  - [2.2. CTYPE Module](#22-ctype-module)
  - [2.3. Attestation Module](#23-attestation-module)
    - [2.3.1. Add](#231-add)
    - [2.3.2. Revoke](#232-revoke)
    - [2.3.3. Lookup](#233-lookup)
  - [2.4. Hierarchy of Trust Module](#24-hierarchy-of-trust-module)
    - [2.4.1. Create root](#241-create-root)
    - [2.4.2. Add delegation](#242-add-delegation)
    - [2.4.3. Revoke](#243-revoke)
  
**Substrate Documentation**

-   [Cumulus Parachain Workshop](https://substrate.dev/cumulus-workshop/#/)
-   [JSON-RPC](https://polkadot.js.org/api/substrate/rpc.html)
-   [Substrate Reference Rust Docs](https://substrate.dev/rustdocs)

## 1. How to use/test locally

### 1.1 Supported Polkadot dependencies

It should at least work until the following commits

-   Polkadot master (newer than 2.0.0) @ `b19f3e1ddc4864f0983fd0531a42550db57d98e9`
-   Cumulus master (Rococo v1) @ `2662bcd3dda634bfafb9632da8fa1fe85a2d71d4`
-   Substrate master (newer than 2.0.0) @ `02771e146f126a9759a62948ec8a2edd6ad47ee9`

### 1.2. How to use

1. Spin up Polkadot validators (number of parachains + 1)
2. Spin up Collator(s)

I recommend checking out the [cumulus-workshop](https://substrate.dev/cumulus-workshop/#/3-parachains/1-launch) and following most of the steps described there, mainly 3.
Unfortunately, some commands there are outdated as the workshop has not been updated to the newest Rococo version, yet.
The following code is basically copied from there and updated to the new version to have a one-page-overview for all commands and steps.
Please check out the workshop for explanations.

### 1.3. Relay Chain: Polkadot

You need to run 2 validators in the relay chain, e.g. `#parachains + 1`.
See [here](https://substrate.dev/cumulus-workshop/#/2-relay-chain/2-launch).

```bash
cargo build --release --features=real-overseer
```

#### 1.3.1. Start Alice's Node

```bash
cargo run --features=real-overseer --release -- \
  --chain rococo-local-v1_2-validators.json \
  --tmp \
  --ws-port 9944 \
  --port 30333 \
  --alice
```

#### 1.3.2. Start Bob's Node

```bash
cargo run --features=real-overseer --release -- \
  --chain rococo-local-v1_2-validators.json \
  --tmp \
  --ws-port 9955 \
  --port 30334 \
  --bob \
```

### 1.4. KILT Collator

Follow the instructions of [section 3](https://substrate.dev/cumulus-workshop/#/3-parachains/1-launch).

For the parachain, you do not need to compile with the `real-overseer` feature:
```
cargo build --release
```

#### 1.4.1. Obtain WASM Validation Function

```
./target/release/kilt-parachain export-genesis-wasm > para-200-wasm
```

#### 1.4.2. Start Collator Node

This assumes your KILT collator repo is a sibling of your Polkadot repo used for the relay chain validators due to using the same precompiled local rococo chainspec.

```
./target/release/kilt-parachain\
  --tmp \
  --ws-port 9977 \
  --port 30336 \
  --parachain-id 200 \
  --validator \
  -- \
  --chain ../polkadot/rococo-local-v1_2-validators.json \
```

#### 1.4.3. Obtain Genesis Head

Either use the following command 

```
./target/release/kilt-parachain export-genesis-state --parachain-id 200 > para-200-genesis
```

Or copy from the logs when starting the parachain

```
2020-08-19 16:46:15 Parachain genesis state: 0x00000000000000000000000000000000000000000000000000000000000000000081f8f537ea138d3340db11484e3d862c9f1faf6742c019cb58fea3f087a5b48c03170a2e7597b7b7e3d84c05391d139a62b157e78786d8c082f29dcf4c11131400
```

#### 1.4.4. Register parachain in Apps

Please note that blocks will be finalized after collating the 6th block.

1. Head to [Polkadot Apps](https://polkadot.js.org/apps/#/?rpc=ws://localhost:9944) and connect to the default local WS address.
2. `Sudo` > `parasSudoWrapper` > `sudoScheduleParaInitialize(id, genesis)`
    1. `id: 200`
    2. `genesisHead`: Add genesis state from step 1.4.3
    3. `validationCode`: Add wasm blob from step 1.4.2
3. Select `Yes` for `parachain: bool` 
4. The Collator should start producing parachain blocks (aka collating) once the registration is successful. 
Please note that this might take some time, up to 10 minutes due to authority discovery.
The collator should start producing log messages like the following:

```
2020-11-10 14:13:12  👶 New epoch 63 launching at block 0xa556…9ea5 (block slot 267502332 >= start slot 267502332).
2020-11-10 14:13:12  👶 Next epoch starts at slot 267502337
2020-11-10 14:13:12  ✨ Imported #302 (0xa556…9ea5)
2020-11-10 14:13:12  Starting collation for relay parent `0xa556…9ea5` on parent `0x03ea…fed6`.
2020-11-10 14:13:12  🙌 Starting consensus session on top of parent 0x03eab53d14b80eab8f6b63e657f54eada7fc52e1ac0032242f41571f9460fed6
2020-11-10 14:13:12  🎁 Prepared block for proposing at 86 [hash: 0xcddeaed47a0ea91d55c2f06190043e71a178ae18f1592619e19a636d180ca071; parent_hash: 0x03ea…fed6; extrinsics (2): [0xee21…4f07, 0xa25d…6c04]]
2020-11-10 14:13:12  Produced proof-of-validity candidate `0x828d55cc65d184753c4c14f190b32598af845fddd147f008e859385ff3b1a306` from block `0xcddeaed47a0ea91d55c2f06190043e71a178ae18f1592619e19a636d180ca071`.
2020-11-10 14:13:12  ✨ Imported #86 (0xcdde…a071)
2020-11-10 14:13:13  💤 Idle (3 peers), best: #302 (0xa556…9ea5), finalized #299 (0x150d…411e), ⬇ 2.2kiB/s ⬆ 4.6kiB/s
2020-11-10 14:13:13  💤 Idle (0 peers), best: #85 (0x03ea…fed6), finalized #84 (0x1e5c…250a), ⬇ 0.7kiB/s ⬆ 0.7kiB/s
2020-11-10 14:13:18  ✨ Imported #303 (0x81a9…d19d)
```

### 1.5 Troubleshoot

#### 1.5.1 Parachain is stuck on #1

Try running all nodes with `--discover-local`. This should not be necessary but might resolve your issue.

#### 1.5.2 Polkadot Apps Extrinsics Error

In case the apps complain about missing types when registering the parachain via a Polkadot validator, try to add the following:
```
{
    "HrmpChannelId": {
      "sender": "u32",
      "receiver": "u32"
    },
    "SignedAvailabilityBitfield": {
      "payload": "BitVec",
      "validator_index": "u32",
      "signature": "Signature"
    },
    "SignedAvailabilityBitfields": "Vec<SignedAvailabilityBitfield>",
    "ValidatorSignature": "Signature",
    "HeadData": "Vec<u8>",
    "CandidateDescriptor": {
      "para_id": "u32",
      "relay_parent": "Hash",
      "collator_id": "Hash",
      "persisted_validation_data_hash": "Hash",
      "pov_hash": "Hash",
      "signature": "Signature"
    },
    "CandidateReceipt": {
      "descriptor": "CandidateDescriptor",
      "commitments_hash": "Hash"
    },
    "UpwardMessage": "Vec<u8>",
    "OutboundHrmpMessage": {
      "recipient": "u32",
      "data": "Vec<u8>"
    },
    "ValidationCode": "Vec<u8>",
    "CandidateCommitments": {
      "upward_messages": "Vec<UpwardMessage>",
      "horizontal_messages": "Vec<OutboundHrmpMessage>",
      "erasure_root": "Hash",
      "new_validation_code": "Option<ValidationCode>",
      "head_data": "HeadData",
      "processed_downward_messages": "u32",
      "hrmp_watermark": "BlockNumber"
    },
    "CommittedCandidateReceipt": {
      "descriptor": "CandidateDescriptor",
      "commitments": "CandidateCommitments"
    },
    "ValidityAttestation": {
      "_enum": {
        "DummyOffsetBy1": "Raw",
        "Implicit": "ValidatorSignature",
        "Explicit": "ValidatorSignature"
      }
    },
    "BackedCandidate": {
      "candidate": "CommittedCandidateReceipt",
      "validity_votes": "Vec<ValidityAttestation>",
      "validator_indices": "BitVec"
    },
    "OriginKind": {
      "_enum": {
        "Native": null,
        "SovereignAccount": null,
        "Superuser": null
      }
    },
    "NetworkId": {
      "_enum": {
        "Any": null,
        "Named": "Vec<u8>",
        "Polkadot": null,
        "Kusama": null
      }
    },
    "MultiLocation": {
      "_enum": {
        "Null": null,
        "X1": "Junction",
        "X2": "(Junction, Junction)",
        "X3": "(Junction, Junction, Junction)",
        "X4": "(Junction, Junction, Junction, Junction)"
      }
    },
    "AccountId32Junction": {
      "network": "NetworkId",
      "id": "AccountId"
    },
    "AccountIndex64Junction": {
      "network": "NetworkId",
      "index": "Compact<u64>"
    },
    "AccountKey20Junction": {
      "network": "NetworkId",
      "index": "[u8; 20]"
    },
    "Junction": {
      "_enum": {
        "Parent": null,
        "Parachain": "Compact<u32>",
        "AccountId32": "AccountId32Junction",
        "AccountIndex64": "AccountIndex64Junction",
        "AccountKey20": "AccountKey20Junction",
        "PalletInstance": "u8",
        "GeneralIndex": "Compact<u128>",
        "GeneralKey": "Vec<u8>",
        "OnlyChild": null
      }
    },
    "VersionedMultiLocation": {
      "_enum": {
        "V0": "MultiLocation"
      }
    },
    "AssetInstance": {
      "_enum": {
        "Undefined": null,
        "Index8": "u8",
        "Index16": "Compact<u16>",
        "Index32": "Compact<u32>",
        "Index64": "Compact<u64>",
        "Index128": "Compact<u128>",
        "Array4": "[u8; 4]",
        "Array8": "[u8; 8]",
        "Array16": "[u8; 16]",
        "Array32": "[u8; 32]",
        "Blob": "Vec<u8>"
      }
    },
    "AbstractFungible": {
      "id": "Vec<u8>",
      "instance": "Compact<u128>"
    },
    "AbstractNonFungible": {
      "class": "Vec<u8>",
      "instance": "AssetInstance"
    },
    "ConcreteFungible": {
      "id": "MultiLocation",
      "amount": "Compact<u128>"
    },
    "ConcreteNonFungible": {
      "class": "MultiLocation",
      "instance": "AssetInstance"
    },
    "MultiAsset": {
      "_enum": {
        "None": null,
        "All": null,
        "AllFungible": null,
        "AllNonFungible": null,
        "AllAbstractFungible": "Vec<u8>",
        "AllAbstractNonFungible": "Vec<u8>",
        "AllConcreteFungible": "MultiLocation",
        "AllConcreteNonFungible": "MultiLocation",
        "AbstractFungible": "AbstractFungible",
        "AbstractNonFungible": "AbstractNonFungible",
        "ConcreteFungible": "ConcreteFungible",
        "ConcreteNonFungible": "ConcreteNonFungible"
      }
    },
    "VersionedMultiAsset": {
      "_enum": {
        "V0": "MultiAsset"
      }
    },
    "DepositAsset": {
      "assets": "Vec<MultiAsset>",
      "dest": "MultiLocation"
    },
    "DepositReserveAsset": {
      "assets": "Vec<MultiAsset>",
      "dest": "MultiLocation",
      "effects": "Vec<Order>"
    },
    "ExchangeAsset": {
      "give": "Vec<MultiAsset>",
      "receive": "Vec<MultiAsset>"
    },
    "InitiateReserveWithdraw": {
      "assets": "Vec<MultiAsset>",
      "reserve": "MultiLocation",
      "effects": "Vec<Order>"
    },
    "InitiateTeleport": {
      "assets": "Vec<MultiAsset>",
      "dest": "MultiLocation",
      "effects": "Vec<Order>"
    },
    "QueryHolding": {
      "query_id": "Compact<u64>",
      "dest": "MultiLocation",
      "assets": "Vec<MultiAsset>"
    },
    "Order": {
      "_enum": {
        "Null": null,
        "DepositAsset": "DepositAsset",
        "DepositReserveAsset": "DepositReserveAsset",
        "ExchangeAsset": "ExchangeAsset",
        "InitiateReserveWithdraw": "InitiateReserveWithdraw",
        "InitiateTeleport": "InitiateTeleport",
        "QueryHolding": "QueryHolding"
      }
    },
    "WithdrawAsset": {
      "assets": "Vec<MultiAsset>",
      "effects": "Vec<Order>"
    },
    "ReserveAssetDeposit": {
      "assets": "Vec<MultiAsset>",
      "effects": "Vec<Order>"
    },
    "TeleportAsset": {
      "assets": "Vec<MultiAsset>",
      "effects": "Vec<Order>"
    },
    "Balances": {
      "query_id": "Compact<u64>",
      "assets": "Vec<MultiAsset>"
    },
    "Transact": {
      "origin_type": "OriginKind",
      "call": "Vec<u8>"
    },
    "RelayTo": {
      "dest": "MultiLocation",
      "inner": "VersionedXcm"
    },
    "RelayedFrom": {
      "superorigin": "MultiLocation",
      "inner": "VersionedXcm"
    },
    "Xcm": {
      "_enum": {
        "WithdrawAsset": "WithdrawAsset",
        "ReserveAssetDeposit": "ReserveAssetDeposit",
        "TeleportAsset": "TeleportAsset",
        "Balances": "Balances",
        "Transact": "Transact",
        "RelayTo": "RelayTo",
        "RelayedFrom": "RelayedFrom"
      }
    },
    "VersionedXcm": {
      "_enum": {
        "V0": "Xcm"
      }
    },
    "XcmError": {
      "_enum": [
        "Undefined",
        "Unimplemented",
        "UnhandledXcmVersion",
        "UnhandledXcmMessage",
        "UnhandledEffect",
        "EscalationOfPrivilege",
        "UntrustedReserveLocation",
        "UntrustedTeleportLocation",
        "DestinationBufferOverflow",
        "CannotReachDestination",
        "MultiLocationFull",
        "FailedToDecode",
        "BadOrigin"
      ]
    },
    "XcmResult": {
      "_enum": {
        "Ok": "()",
        "Err": "XcmError"
      }
    },
    "BlockWeights": {
      "base_block": "Weight",
      "max_block": "Weight",
      "per_class": "PerDispatchClass<WeightsPerClass>"
    },
      "WeightsPerClass": {
      "base_extrinsic": "Weight",
      "max_extrinsic": "Option<Weight>",
      "max_total": "Option<Weight>",
      "reserved": "Option<Weight>"
    },
    "PerDispatchClass<WeightsPerClass>": {
      "normal": "WeightsPerClass",
      "operational": "WeightsPerClass",
      "mandatory": "WeightsPerClass"
    },
    "PerDispatchClass": {
      "normal": "u32",
      "operational": "u32",
      "mandatory": "u32"
    }
}
```

## 2. Node Modules functionalities

The KILT blockchain is the heart and soul behind KILT protocol. It provides the immutable
transaction ledger for the various processes in the network.

`Building on the Parity Substrate Blockchain Framework`

During our first whiteboard phase, we were thinking about developing the KILT protocol on
Ethereum smart-contracts, but we realised that we would have less freedom of setting
transaction costs, while incurring a high level of overhead. Instead, we started our
development on [Parity Substrate](https://www.parity.io/substrate/), a general blockchain framework, and built up the KILT blockchain from scratch based on its module library.

Building our blockchain on Parity Substrate has multiple advantages. Substrate has a very
good fundamental [architecture](https://docs.substrate.dev/docs/architecture-of-a-runtime) and [codebase](https://github.com/paritytech/substrate) created by blockchain experts. Substrate
framework is developed in Rust, a memory efficient and fast compiled system programming
language, which provides a secure environment with virtually no runtime errors. Moreover, the
node runtime is also compiled to WebAssembly, so older version native nodes can always run
the latest version node runtime in a WebAssembly virtual machine to bypass the problem of a
blockchain fork. Importantly, there is a vibrant developer community and rich [documentation](https://docs.substrate.dev/).

Our implementation is based on the [substrate-node-template](https://github.com/rstormsf/substrate-node-template) library (skeleton template for
quickly building a substrate based blockchain), which is linked to the main Substrate
codebase.

**Remote Procedure Calls**

The Ethereum ecosystem highly leverages [JSON-RPC](https://www.jsonrpc.org/specification) where one can efficiently call methods and parameters directly on the blockchain node. Based on good experiences, developers
decided to use it in Substrate as well. The [Polkadot API](https://polkadot.js.org/api/) helps with communicating with the JSON-RPC endpoint, and the clients and services never have to talk directly with the endpoint.

**Blocktime**

The blocktime is currently set to 5 seconds, but this setting is subject to change based on
further research. We will consider what is affected by this parameter, and in the long term it
will be fine-tuned to a setting that provides the best performance and user experience for the
participants of the KILT network.

**Extrinsics and Block Storage**

In Substrate, the blockchain transactions are abstracted away and are generalised as
[extrinsics](https://docs.substrate.dev/docs/extrinsics) in the system. They are called extrinsics since they can represent any piece of information that is regarded as input from “the outside world” (i.e. from users of the network) to the blockchain logic. The blockchain transactions in KILT are implemented through these
general extrinsics, that are signed by the originator of the transaction. We use this framework
to write the KILT Protocol specific data entries on the Substrate based KILT blockchain: [DID],
[CTYPEhash], [Attestation] and [Delegation]. The processing of each of these entry types is
handled by our custom Substrate runtime node modules.

Under the current consensus algorithm, authority validator nodes (whose addresses are listed
in the genesis block) can create new blocks. These nodes [validate](https://docs.substrate.dev/docs/transaction-lifecycle-in-substrate) incoming transactions, put
them into the pool, and include them in a new block. While creating the block, the node
executes the transactions and stores the resulting state changes in its local storage. Note that
the size of the entry depends on the number of arguments the transaction, (i.e., the respective
extrinsic method) has. The size of the block is hence dynamic and will depend on the number
and type of transactions included in the new block. The valid new blocks are propagated
through the network and other nodes execute these blocks to update their local state (storage).

**Authoring & Consensus Algorithm**

We use [Aura](https://wiki.parity.io/Aura) as the authoring algorithm, since we are still in a permissioned blockchain mode.
We will probably move to another algorithm in the future (e.g. [BABE](https://w3f-research.readthedocs.io/en/latest/polkadot/BABE.html)).

For consensus we use [GRANDPA](https://github.com/paritytech/substrate#2-description).

At a later stage, we most likely will change to a different consensus algorithm that will incorporate additional features (e.g. proving availability of certain services) and we might leverage concepts from BABE+GRANDPA while designing this new consensus mechanism.

**Polkadot Integration**

As a further great advantage, by basing ourselves on Substrate we can easily connect to the
Polkadot ecosystem. This could provide security for the KILT network by leveraging the global
consensus in the Polkadot network. We are planning to integrate KILT into the [Polkadot](https://polkadot.network/)
network. It is fairly straightforward to achieve that by simply including specific Substrate
modules into the KILT Validator Node implementation. The exact details of this integration is
subject to future agreements between Polkadot and KILT and the technological development
of Polkadot, Substrate and KILT.

**KILT Tokens**

Coin transfer is implemented as a balance-based mechanism in Substrate. In our testnet,
every new identity gets 1000 KILT Tokens from a root entity in the system who is wired into
the genesis block. At a later stage in the testnet (Mash-Net) and the persistent testnet (WashNet), we are proposing to provide KILT Tokens for new developers wanting to join our network
on a simple request-provide based mechanism. Preferably, developers will be able to register
on our website, and we manually transfer KILT tokens to the registered developers.
Importantly, these test tokens will not be usable on our mainnet. After the launch of the mainnet
(Spirit-Net) and the public KILT Token sale, tokens will be available on cryptocurrency
exchanges.

### 2.1. DID Module

The KILT blockchain node runtime defines an DID module exposing:

#### 2.1.1. Add

```rust
add(origin, sign_key: T::PublicSigningKey, box_key: T::PublicBoxKey, doc_ref: Option<Vec<u8>>) -> Result
```

This function takes the following parameters:

-   origin: public [ss58](<https://wiki.parity.io/External-Address-Format-(SS58)>) address of the caller of the method
-   sign_key: the [ed25519](http://ed25519.cr.yp.to/) public signing key of the owner
-   box_key: the [x25519-xsalsa20-poly1305](http://nacl.cr.yp.to/valid.html) public encryption key of the owner
-   doc_ref: Optional u8 byte vector representing the reference (URL) to the DID
    document

The blockchain node verifies the transaction signature corresponding to the owner and
inserts it to the blockchain storage by using a map (done by the substrate framework):

```rust
T::AccountId => (T::PublicSigningKey, T::PublicBoxKey, Option<Vec<u8>>)
```

#### 2.1.2. CRUD

As DID supports CRUD (Create, Read, Update, Delete) operations, a `get(dids)` method
reads a DID for an account address, the add function may also be used to update a DID and
a `remove(origin) -> Result` function that takes the owner as a single parameter removes the DID from the
map, so any later read operation call does not return the data of a removed DID.

### 2.2. CTYPE Module

The KILT blockchain node runtime defines an CTYPE module exposing

```rust
add(origin, hash: T::Hash) -> Result
```

This function takes following parameters:

-   origin: public [ss58](<https://wiki.parity.io/External-Address-Format-(SS58)>) address of the caller of the method
-   hash: CTYPE hash as a [blake2b](https://blake2.net/) string

The blockchain node verifies the transaction signature corresponding to the creator and
inserts it to the blockchain storage by using a map (done by the substrate framework):

```rust
T::Hash => T::AccountId
```

### 2.3. Attestation Module

The KILT blockchain node runtime defines an Attestation module exposing functions to

-   add an attestation (`add`)
-   revoke an attestation (`revoke`)
-   lookup an attestation (`lookup`)
-   lookup attestations for a delegation (used later in Complex Trust Structures)
    on chain.

#### 2.3.1. Add

```rust
add(origin, claim_hash: T::Hash, ctype_hash: T::Hash, delegation_id: Option<T::DelegationNodeId>) -> Result
```

The `add` function takes following parameters:

-   origin: The caller of the method, i.e., public address ([ss58](<https://wiki.parity.io/External-Address-Format-(SS58)>)) of the Attester
-   claim_hash: The Claim hash as [blake2b](https://blake2.net/) string used as the key of the entry
-   ctype_hash: The [blake2b](https://blake2.net/) hash of CTYPE used when creating the Claim
-   delegation_id: Optional reference to a delegation which this attestation is based
    on

The node verifies the transaction signature and insert it to the state, if the provided attester
didn’t already attest the provided claimHash. The attestation is stored by using a map:

```rust
T::Hash => (T::Hash,T::AccountId,Option<T::DelegationNodeId>,bool)
```

Delegated Attestations are stored in an additional map:

```rust
T::DelegationNodeId => Vec<T::Hash>
```

#### 2.3.2. Revoke

```rust
revoke(origin, claim_hash: T::Hash) -> Result
```

The `revoke` function takes the claimHash (which is the key to lookup an attestation) as
argument. After looking up the attestation and checking invoker permissions, the revoked
flag is set to true and the updated attestation is stored on chain.

#### 2.3.3. Lookup

The attestation lookup is performed with the `claimHash`, serving as the key to the
attestation store. The function `get_attestation(claimHash)` is exposed to the outside
clients and services on the blockchain for this purpose.

Similarly, as with the simple lookup, to query all attestations created by a certain delegate,
the runtime defines the function `get_delegated_attestations(DelegationNodeId)`
that is exposed to the outside.

### 2.4. Hierarchy of Trust Module

The KILT blockchain node runtime defines a Delegation module exposing functions to

-   create a root `create_root`
-   add a delegation `add_delegation`
-   revoke a delegation `revoke_delegation`
-   revoke a whole hierarchy `revoke_root`
-   lookup a root `get(root)`
-   lookup a delegation `get(delegation)`
-   lookup children of a delegation `get(children)`
    on chain.

#### 2.4.1. Create root

```rust
create_root(origin, root_id: T::DelegationNodeId, ctype_hash: T::Hash) -> Result
```

The `create_root` function takes the following parameters:

-   origin: The caller of the method, i.e., public address (ss58) of the owner of the
    trust hierarchy
-   root_id: A V4 UUID identifying the trust hierarchy
-   ctype_hash: The blake2b hash of the CTYPE the trust hierarchy is associated with

The node verifies the transaction signature and insert it to the state. The root is stored by using
a map:

```rust
T::DelegationNodeId => (T::Hash,T::AccountId,bool)
```

#### 2.4.2. Add delegation

```rust
add_delegation(origin, delegation_id: T::DelegationNodeId, root_id: T::DelegationNodeId, parent_id: Option<T::DelegationNodeId>, delegate: T::AccountId, permissions: Permissions, delegate_signature: T::Signature) -> Result
```

The `add_delegation` function takes the following parameters:

-   origin: The caller of the method, i.e., public address (ss58) of the delegator
-   delegation_id: A V4 UUID identifying this delegation
-   root_id: A V4 UUID identifying the associated trust hierarchy
-   parent_id: Optional, a V4 UUID identifying the parent delegation this delegation is
    based on
-   CTYPEHash: The blake2b hash of CTYPE used when creating the Claim
-   delegate: The public address (ss58) of the delegate (ID receiving the delegation)
-   permissions: The permission bit set (having 0001 for attesting permission and
    0010 for delegation permission)
-   delegate_signature: ed25519 based signature by the delegate based on the
    delegationId, rootId, parentId and permissions

The node verifies the transaction signature and the delegate signature as well as all other data
to be valid and the delegator to be permitted and then inserts it to the state. The delegation is
stored by using a map:

```rust
T::DelegationNodeId => (T::DelegationNodeId,Option<T::DelegationNodeId>,T::AccountId,Permissions,bool)
```

Additionally, if the delegation has a parent delegation, the information about the children of its
parent is updated in the following map that relates parents to their children:

```rust
T::DelegationNodeId => Vec<T::DelegationNodeId>
```

#### 2.4.3. Revoke

```rust
revoke_root(origin, root_id: T::DelegationNodeId) -> Result
```

and

```rust
revoke_delegation(origin, delegation_id: T::DelegationNodeId) -> Result
```
