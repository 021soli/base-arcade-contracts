# Base Arcade Contracts

Solidity contracts behind the **Base Arcade** family of mini-games on the [Base](https://base.org) network. Each contract is small and cheap to call: no tokens, no ETH transfers, only per-player state (best score, daily claim, streak) that the game UI reads back.

## Deployed contracts (Base Mainnet)

| Game | Contract | Address |
|------|----------|---------|
| Base Bastion (tower defense) | [`BaseBastion.sol`](contracts/BaseBastion.sol) | [`0xb91ab398ecd7c821bb7ed0bc41232f8d2ee3e0f4`](https://basescan.org/address/0xb91ab398ecd7c821bb7ed0bc41232f8d2ee3e0f4) |
| Base Invaders (space shooter) | [`BaseInvaders.sol`](contracts/BaseInvaders.sol) | [`0xBa90aACc929D0B1512Ffd0BcF538f4Ec8804770a`](https://basescan.org/address/0xBa90aACc929D0B1512Ffd0BcF538f4Ec8804770a) |
| Base Runner (endless runner) | [`BaseRunner.sol`](contracts/BaseRunner.sol) | [`0xDff0709C49530C02deF4F9B4460E2Fe558a09d41`](https://basescan.org/address/0xDff0709C49530C02deF4F9B4460E2Fe558a09d41) |

## Shared design

- **Per-player stats** stored in `mapping(address => PlayerStats)`.
- **Daily claim** with a 24-hour cooldown (and a streak that survives a 48-hour grace window in Bastion and Invaders).
- **Events** for every action, so you can index activity off-chain.
- **One view call** (`getPlayerStats`) returns everything a UI needs.

## Functions at a glance

### BaseBastion
| Function | What it does |
|----------|--------------|
| `startRun()` | Records the start of a defense run (`totalRuns += 1`). |
| `saveScore(score, wave)` | Saves best score and wave if they beat the previous best. |
| `claimDailyBoost()` | Once per 24 h; tracks the claim streak. |
| `getPlayerStats(player)` | Best score/wave, runs, claims, streak, and `canClaimNow`. |
| `timeUntilNextClaim(player)` | Seconds until the next claim is available. |

### BaseInvaders
`saveScore`, `claimDailyBoost`, `getPlayerStats`, same pattern as above.

### BaseRunner
`claimDailyRun(distanceMeters)`, `dailyCheckIn()`, `bestDistanceOf(player)`, `lastCheckInOf(player)`.

## Deploy with Remix

1. Open [remix.ethereum.org](https://remix.ethereum.org) and create a new file from one of the contracts in `contracts/`.
2. In **Solidity Compiler**, pick a version that satisfies the file's `pragma` (0.8.24 or newer) and compile.
3. In **Deploy & Run**, choose **Injected Provider** (MetaMask) with the network set to **Base** (chain ID 8453), then deploy.
4. Verify the source on [BaseScan](https://basescan.org/verifyContract) (single-file method, same compiler version and optimizer settings as in Remix).

## Builder Code attribution (ERC-8021)

The games append a Base Builder Code suffix to transaction calldata for onchain attribution. The contracts ignore the extra trailing bytes, so no contract change is needed.

## A note on scores

`saveScore` is self-reported by the player's client. A simple contract cannot verify that a score was earned legitimately. Treat these contracts as a fun onchain activity log and leaderboard, not a cheat-proof competitive ranking. A trustworthy ranking would need a server-signed score or a proof of the game's execution.

## License

[MIT](LICENSE)
