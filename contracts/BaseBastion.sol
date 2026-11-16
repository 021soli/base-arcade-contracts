// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Base Bastion — onchain run tracker + score + daily boost
/// @notice Lightweight, gas-cheap contract: no tokens, no ETH transfers.
///         Records every run start, each player's best run (score + wave
///         reached), and gates a once-per-24h "daily boost" claim — all
///         readable back for the game's UI. Same design as
///         BaseInvaders.sol / BaseRunner.sol so the whole Base Arcade
///         family shares one predictable pattern.
contract BaseBastion {
    struct PlayerStats {
        uint256 bestScore;
        uint256 bestWave;
        uint256 totalRuns;
        uint256 lastClaimTimestamp;
        uint256 totalClaims;
        uint256 currentStreak;
    }

    mapping(address => PlayerStats) public stats;

    uint256 public constant CLAIM_COOLDOWN = 1 days;
    uint256 public constant STREAK_GRACE = 2 days; // claim again within this window to keep the streak

    event RunStarted(address indexed player, uint256 timestamp, uint256 totalRuns);
    event ScoreSaved(address indexed player, uint256 score, uint256 wave, uint256 timestamp);
    event DailyBoostClaimed(address indexed player, uint256 timestamp, uint256 totalClaims, uint256 currentStreak);

    /// @notice Called once when a player begins a defense run. This is what
    /// the game's "Start Defense (On-Chain)" / "Defend Again (On-Chain)"
    /// buttons actually call — so that transaction records something real
    /// instead of being a plain empty self-transfer.
    function startRun() external {
        PlayerStats storage s = stats[msg.sender];
        s.totalRuns += 1;
        emit RunStarted(msg.sender, block.timestamp, s.totalRuns);
    }

    /// @notice Save your best defense run. Only updates storage if it's an
    /// actual new best, but the event fires every time in case you want to
    /// index every attempt off-chain.
    function saveScore(uint256 score, uint256 wave) external {
        PlayerStats storage s = stats[msg.sender];
        if (score > s.bestScore) {
            s.bestScore = score;
            s.bestWave = wave;
        }
        emit ScoreSaved(msg.sender, score, wave, block.timestamp);
    }

    /// @notice Claim the once-per-24h boost. Reverts if still on cooldown.
    /// Claiming again within STREAK_GRACE of the last claim keeps your streak
    /// going; waiting longer than that resets it to 1.
    function claimDailyBoost() external {
        PlayerStats storage s = stats[msg.sender];
        require(
            block.timestamp >= s.lastClaimTimestamp + CLAIM_COOLDOWN,
            "BaseBastion: daily boost still on cooldown"
        );

        if (s.lastClaimTimestamp != 0 && block.timestamp <= s.lastClaimTimestamp + STREAK_GRACE) {
            s.currentStreak += 1;
        } else {
            s.currentStreak = 1;
        }

        s.lastClaimTimestamp = block.timestamp;
        s.totalClaims += 1;
        emit DailyBoostClaimed(msg.sender, block.timestamp, s.totalClaims, s.currentStreak);
    }

    /// @notice Convenience getter — everything the game's UI needs in one call.
    function getPlayerStats(address player)
        external
        view
        returns (
            uint256 bestScore,
            uint256 bestWave,
            uint256 totalRuns,
            uint256 lastClaimTimestamp,
            uint256 totalClaims,
            uint256 currentStreak,
            bool canClaimNow
        )
    {
        PlayerStats memory s = stats[player];
        return (
            s.bestScore,
            s.bestWave,
            s.totalRuns,
            s.lastClaimTimestamp,
            s.totalClaims,
            s.currentStreak,
            block.timestamp >= s.lastClaimTimestamp + CLAIM_COOLDOWN
        );
    }

    /// @notice Seconds remaining until this player can claim again (0 if claimable now).
    function timeUntilNextClaim(address player) external view returns (uint256) {
        PlayerStats memory s = stats[player];
        uint256 nextClaim = s.lastClaimTimestamp + CLAIM_COOLDOWN;
        if (block.timestamp >= nextClaim) return 0;
        return nextClaim - block.timestamp;
    }
}
