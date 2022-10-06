# Building on Fuel with Sway - Web3RSVP

In this workshop, we'll build a fullstack event creation and management platform on Fuel. 

This platform is similar to Eventbrite or Luma. Users can create a new event and RSVP to an existing event. This is the functionality we're going to build out in this workshop:
- Create a function in the smart contract to create a new event
- Create a function in the smart contract to RSVP to an existing event

Let's break down the tasks associated with each function:

1. In order to create a function to create a new event, the program will have to be able to handle the following:
- the user should pass in the name of the event, a deposit amount for attendees to pay to be able to RSVP to the event, and the max capacity for the event. 
- Once a user passes this information in, our program should create an event, represented as a data structure called a `struct`. 
- Because this is an events platform, our program should be able to handle multiple events at once. Therefore, we need a mechanism to store multiple events.
- To store multiple events, we will use a hash map, someimtes known as a ___ in other programming languages. This hash map will `map` a unique identifier, which we'll call an `eventId`, to an event (that is represented as a struct). 

2. In order to create a function to handle a user RSVP'ing, or confirming their attendance to the event, our program will have to be able to handle the following: 
- We should have a mechsnism to identify the event that the user 

*Some resources that may be helpful:*
- [Fuel Book](https://fuellabs.github.io/fuel-docs/master/)
- [Sway Book](https://fuellabs.github.io/sway/v0.19.2/)
- [Fuel discord](discord.gg/fuelnetwork) - get help

### Installation

1. Install `cargo` using [`rustup`](https://www.rust-lang.org/tools/install)

    Mac and Linux:
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

2. Check for correct setup:

    ```bash
    $ cargo --version
    cargo 1.62.0
    ```

3. Install `forc` using [`fuelup`](https://fuellabs.github.io/sway/v0.18.1/introduction/installation.html#installing-from-pre-compiled-binaries)

    Mac and Linux:
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf \
    https://fuellabs.github.io/fuelup/fuelup-init.sh | sh
    ```

4. Check for correct setup:

    ```bash
    $ forc --version
    forc 0.18.1
    ```
## Getting Started

This guide will walk developers through writing a smart contract in Sway, a simple test, deploying to Fuel, and building a frontend.

Before we begin, it may be helpful to understand terminology that will used throughout the docs and how they relate to each other:

- **Fuel**: the Fuel blockchain.
- **FuelVM**: the virtual machine powering Fuel.
- **Sway**: the domain-specific language crafted for the FuelVM; it is inspired by Rust.
- **Forc**: the build system and package manager for Sway, similar to Cargo for Rust.

## Understand Sway Program Types

There are four types of Sway programs:

- `contract`
- `predicate`
- `script`
- `library`

Contracts, predicates, and scripts can produce artifacts usable on the blockchain, while a library is simply a project designed for code reuse and is not directly deployable.

The main features of a smart contract that differentiate it from scripts or predicates are that it is callable and stateful.

A script is runnable bytecode on the chain which can call contracts to perform some task. It does not represent ownership of any resources and it cannot be called by a contract.

## Create a new Fuel project

**Start by creating a new, empty folder. We'll call it `Web3RSVP`.**

### Writing the Contract

Then with `forc` installed, create a project inside of your `Web3RSVP` folder:

```sh
$ cd Web3RSVP
$ forc new eventPlatform
To compile, use `forc build`, and to run tests use `forc test`

---
```

Here is the project that `Forc` has initialized:

```console
$ tree Web3RSVP
eventPlatform
├── Cargo.toml
├── Forc.toml
├── src
│   └── main.sw
└── tests
    └── harness.rs
```

## Defining the ABI

First, we'll define the ABI. An ABI defines an interface, and there is no function body in the ABI. A contract must either define or import an ABI declaration and implement it. It is considered best practice to define your ABI in a separate library and import it into your contract because this allows callers of the contract to import and use the ABI in scripts to call your contract.

To define the ABI as a library, we'll create a new file in the `src` folder. Create a new file named `event_platform.sw`  

Here is what your project structure should look like now:
Here is the project that `Forc` has initialized:

```console
eventPlatform
├── Cargo.toml
├── Forc.toml
├── src
│   └── main.sw
│   └── event_platform.sw
└── tests
    └── harness.rs
```

Add the following code to your ABI file, `event_platform.sw`: 

``` rust
library event_platform;

use std::{
    identity::Identity,
    contract_id::ContractId,
};

abi eventPlatform {
    #[storage(read, write)]
    fn create_event(maxCapacity: u64, deposit: u64, eventName: str[10]) -> Event;

    #[storage(read, write)]
    fn rsvp(eventId: u64) -> Event;
}

// defining the struct here because it would be used by other developers who would be importing this ABI
pub struct Event {
    uniqueId: u64,
    maxCapacity: u64, 
    deposit: u64, 
    owner: Identity,
    name: str[10],
    numOfRSVPs: u64
}

```

Now, in the `main.sw` file, we'll implement these functions. This is where you will write out the function bodies. Here is what your `main.sw` file should look like:

```rust
contract;

dep event_platform;
use event_platform::*;

use std::{
    identity::Identity,
    contract_id::ContractId,
    storage::StorageMap,
    chain::auth::{AuthError, msg_sender},
    context::{call_frames::msg_asset_id, msg_amount, this_balance},
    result::Result,
};

storage {
    events: StorageMap<u64, Event> = StorageMap {},
    event_id_counter: u64 = 0,
}

impl eventPlatform for Contract{
    #[storage(read, write)]
    fn create_event(capacity: u64, price: u64, eventName: str[10]) -> Event {
       let campaign_id = storage.event_id_counter;
       let newEvent = Event {
        uniqueId: campaign_id,
        maxCapacity: capacity,
        deposit: price,
        owner: msg_sender().unwrap(),
        name: eventName,
        numOfRSVPs: 0
       };
 

       storage.events.insert(campaign_id, newEvent);
       storage.event_id_counter += 1;
       let mut selectedEvent = storage.events.get(storage.event_id_counter -1);
       return selectedEvent;
    }

    #[storage(read, write)]
    fn rsvp(eventId: u64) -> Event {
    //variables are immutable by default, so you need to use the mut keyword
    let mut selectedEvent = storage.events.get(eventId);
    if (eventId > storage.event_id_counter) {
        //if the user passes in an eventID that does not exist, return the first event
        let fallback = storage.events.get(0);
        return fallback;
    }
    //send the money from the msg_sender to the owner of the selected event
    selectedEvent.numOfRSVPs += 1;
    storage.events.insert(eventId, selectedEvent);
    return selectedEvent;
    }
}
```
### Build the Contract

From inside the `web3rsvp/eventPlatform` directory, run the following command to build your contract:

```console
$ forc build
  Compiled library "core".
  Compiled library "std".
  Compiled contract "counter_contract".
  Bytecode size is 224 bytes.
```

### Deploy the Contract

It's now time to deploy the contract to the testnet. We will show how to do this using `forc` from the command line, but you can also do it using the [Rust SDK](https://github.com/FuelLabs/fuels-rs#deploying-a-sway-contract) or the [TypeScript SDK](https://github.com/FuelLabs/fuels-ts/#deploying-contracts).

In order to deploy a contract, you need to have a wallet to sign the transaction and coins to pay for gas. First, we'll create a wallet.

#### Install the Wallet CLI

Follow [these steps to set up a wallet and create an account](https://github.com/FuelLabs/forc-wallet#forc-wallet).

After typing in a password, be sure to save the mnemonic phrase that is output.

With this, you'll get a fuel address that looks something like this: `fuel1efz7lf36w9da9jekqzyuzqsfrqrlzwtt3j3clvemm6eru8fe9nvqj5kar8`. Save this address as you'll need it to sign transactions when we deploy the contract.

#### Get Testnet Coins

With your account address in hand, head to the [testnet faucet](https://faucet-beta-1.fuel.network/) to get some coins sent to your wallet.

## Deploy To Testnet

Now that you have a wallet, you can deploy with `forc deploy` and passing in the testnet endpoint like this:

`forc deploy --url https://node-beta-1.fuel.network/graphql --gas-price 1`

> **Note**
> We set the gas price to 1. Without this flag, the gas price is 0 by default and the transaction will fail.

The terminal will ask for the address of the wallet you want to sign this transaction with, paste in the address you saved earlier, it looks like this: `fuel1efz7lf36w9da9jekqzyuzqsfrqrlzwtt3j3clvemm6eru8fe9nvqj5kar8`

The terminal will output your contract id. Be sure to save this as you will need it to build a frontend with the Typescript SDK.

The terminal will output a `transaction id to sign` and prompt you for a signature. Open a new terminal tab and view your accounts by running `forc wallet list`. If you followed these steps, you'll notice you only have one account, `0`.

Grab the `transaction id` from your other terminal and sign with a specified account by running the following command:

``` console
forc wallet sign` + `[transaction id here, without brackets]` + `[the account number, without brackets]`
```

Your command should look like this:

``` console
$ forc wallet sign 16d7a8f9d15cfba1bd000d3f99cd4077dfa1fce2a6de83887afc3f739d6c84df 0
Please enter your password to decrypt initialized wallet's phrases:
Signature: 736dec3e92711da9f52bed7ad4e51e3ec1c9390f4b05caf10743229295ffd5c1c08a4ca477afa85909173af3feeda7c607af5109ef6eb72b6b40b3484db2332c
```

Enter your password when prompted, and you'll get back a `signature`. Save that signature, and return to your other terminal window, and paste that in where its prompting you to `provide a signature for this transaction`.

Finally, you will get back a `TransactionId` to confirm your contract was deployed. With this ID, you can head to the [block explorer](https://fuellabs.github.io/block-explorer-v2/) and view your contract.

> **Note**
> You should prefix your `TransactionId` with `0x` to view it in the block explorer

## Create a Frontend to Interact with Contract

Now we are going to

1. **Initialize a React project.**
2. **Install the `fuels` SDK dependencies.**
3. **Modify the App.**
4. **Run our project.**

### Initialize a React project

To split better our project let's create a new folder `frontend` and initialize our project inside it.

In the terminal, go back up one directory and initialize a react project using [`Create React App`](https://create-react-app.dev/).

```console
$ cd ..
$ npx create-react-app frontend --template typescript
Success! Created frontend at Fuel/fuel-project/frontend
```

You should now have your outer folder, `fuel-project`, with two folders inside: `front-end` and `fuel-contract`

![project folder structure](./images/quickstart-folder-structure.png)

#### Install the `fuels` SDK dependencies

On this step we need to install 3 dependencies for the project:

1. `fuels`: The umbrella package that includes all the main tools; `Wallet`, `Contracts`, `Providers` and more.
2. `fuelchain`: Fuelchain is the ABI TypeScript generator.
3. `typechain-target-fuels`: The Fuelchain Target is the specific interpreter for the [Fuel ABI Spec](https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/abi.md).

> ABI stands for Application Binary Interface. ABI's inform the application the interface to interact with the VM, in other words, they provide info to the APP such as what methods a contract has, what params, types it expects, etc...

##### Install

Move into the `frontend` folder, then install the dependencies:

```console
$ cd frontend
$ npm install fuels --save
added 65 packages, and audited 1493 packages in 4s
$ npm install fuelchain typechain-target-fuels --save-dev
added 33 packages, and audited 1526 packages in 2s
```

##### Generating contract types

To make it easier to interact with our contract we use `fuelchain` to interpret the output ABI JSON from our contract. This JSON was created on the moment we executed the `forc build` to compile our Sway Contract into binary.

If you see the folder `fuel-project/counter_contract/out` you will be able to see the ABI JSON there. If you want to learn more, read the [ABI Specs here](https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/abi.md).

Inside `counter-contract/frontend` run;

```console
$ npx fuelchain --target=fuels --out-dir=./src/contracts ../counter_contract/out/debug/*-abi.json
Successfully generated 4 typings!
```

Now you should be able to find a new folder `fuel-project/frontend/src/contracts`. This folder was auto-generated by our `fuelchain` command, this files abstract the work we would need to do to create a contract instance, and generate a complete TypeScript interface to the Contract, making easy to develop.

### Create A Wallet (Again)

For interacting with the fuel network we have to submit signed transactions with enough funds to cover network fees. The Fuel TS SDK don't currently support Wallet integrations, requiring us to have a non-safe wallet inside the WebApp using a privateKey.

> **Note**
>This should be done only for development purpose. Never expose a web app with a private key inside. The Fuel Wallet is in active development, follow the progress [here](https://github.com/FuelLabs/fuels-wallet).

In the root of the frontend project create a file, createWallet.js

```js
const { Wallet } = require("fuels");

const wallet = Wallet.generate();

console.log("address", wallet.address.toString());
console.log("private key", wallet.privateKey);
```

In a terminal, run the following command:

``` console
$ node createWallet.js
address fuel160ek8t7fzz89wzl595yz0rjrgj3xezjp6pujxzt2chn70jrdylus5apcuq
private key 0x719fb4da652f2bd4ad25ce04f4c2e491926605b40e5475a80551be68d57e0fcb
```

> **Note**
> You should use the generated address and private key.

Save the private key, you will need this later to set it as a string value for a variable `WALLET_SECRET` in your `App.tsx` file. More on that below.

First, take the address of your wallet and use it to get some coins from [the testnet faucet](https://faucet-beta-1.fuel.network/).

Now you're ready to build and ship ⛽

> **Note**
> The team is working to simplify the process of creating a wallet, and eliminate the need to create a wallet twice. Keep an eye out for these updates.

### Editor

You are welcome to use your editor of choice.

- [VSCode plugin](https://marketplace.visualstudio.com/items?itemName=FuelLabs.sway-vscode-plugin)
- [Vim highlighting](https://github.com/FuelLabs/sway.vim)

## Writing your smart contract
