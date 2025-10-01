# Decentralized Time-Release Safe (Clarity Smart Contracts)

This project implements **time-lock safes** with inheritance and penalty features using Clarity on the Stacks blockchain.

---

## Contracts

### `time-release-safe.clar`
- Owner locks STX until a future block height.
- Only owner can withdraw after unlock.
- Prevents overlapping locks.

### `beneficiary-safe.clar`
- Adds support for **one beneficiary**.
- After unlock, either owner or beneficiary can withdraw.

### `multi-beneficiary-safe.clar`
- Supports **multiple beneficiaries with percentage shares**.
- If withdrawn before unlock:
  - Owner can withdraw early but pays a penalty (default: 10%).
- If withdrawn after unlock:
  - Funds are automatically distributed among beneficiaries based on their shares.

---

## Setup

1. Install [Clarinet](https://docs.hiro.so/clarity/clarinet).
2. Run checks:
   ```bash
   clarinet check
