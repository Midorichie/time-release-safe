import { Clarinet, Tx, Chain, Account } from "clarinet";

Clarinet.test({
  name: "Ensure funds can be locked and withdrawn after unlock block",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    // Lock funds until block 50
    let block = chain.mineBlock([
      Tx.contractCall("time-release-safe", "lock", ["u50"], deployer.address),
    ]);
    block.receipts[0].result.expectOk();

    // Try to withdraw before unlock (should fail)
    let earlyWithdraw = chain.mineBlock([
      Tx.contractCall("time-release-safe", "withdraw", [], deployer.address),
    ]);
    earlyWithdraw.receipts[0].result.expectErr();

    // Advance to block 50
    chain.mineEmptyBlockUntil(50);

    // Withdraw after unlock (should succeed)
    let lateWithdraw = chain.mineBlock([
      Tx.contractCall("time-release-safe", "withdraw", [], deployer.address),
    ]);
    lateWithdraw.receipts[0].result.expectOk();
  },
});
