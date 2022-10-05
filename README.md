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
    fn create_event(maxCapacity: u64, deposit: u64, eventName: str[10]) -> bool;

    #[storage(read, write)]
    fn rsvp(eventId: u64) -> Event;
}

// defining the struct here because it would be used by other developers who would be importing this ABI
pub struct Event {
    maxCapacity: u64, 
    deposit: u64, 
    owner: Identity,
    name: str[10],
    numOfRSVPs: u64
}
```



### Editor

You are welcome to use your editor of choice.

- [VSCode plugin](https://marketplace.visualstudio.com/items?itemName=FuelLabs.sway-vscode-plugin)
- [Vim highlighting](https://github.com/FuelLabs/sway.vim)

## Writing your smart contract
