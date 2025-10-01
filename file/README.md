# Decentralized Time-Release Safe (Clarity Smart Contracts)

This project implements **time-lock safes** using Clarity on the Stacks blockchain.

---

## Features
### `time-release-safe.clar`
- Owner can lock STX until a specified future block height.
- Only the owner can withdraw after unlock.
- Prevents multiple overlapping locks.

### `beneficiary-safe.clar`
- Adds support for a **beneficiary** (inheritance use case).
- Owner sets a beneficiary at lock time.
- After unlock, either the **owner** or **beneficiary** can withdraw.

---

## Setup
1. Install [Clarinet](https://docs.hiro.so/clarity/clarinet).
2. Run checks:
   ```bash
   clarinet check
