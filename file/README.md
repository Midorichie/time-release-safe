# Decentralized Time-Release Safe (Clarity Smart Contract)

This project implements a **time-lock safe** using Clarity on the Stacks blockchain.  
It allows a user to deposit STX into the contract, which can only be withdrawn **after a specific block height (future time)**.

---

## Features
- Lock funds until a specified future block height.
- Owner-only withdrawal after lock expires.
- Secure, simple, and modular design.

---

## Project Setup

1. Install [Clarinet](https://docs.hiro.so/clarity/clarinet)
   ```bash
   brew install clarinet
