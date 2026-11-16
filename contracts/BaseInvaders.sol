// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * BaseInvaders
 * ------------
 * Minimal on-chain backend for the Base Invaders game:
 *   1. saveScore(score, wave)   -> records a player's best score/wave (only
 *                                   updates if it beats their previous best)
 *   2. claimDailyBoost()        -> once every 24h per wallet, also tracks a
 *                                   claim streak (like the in-game daily boost)
 *   3. getPlayerStats(address)  -> a single view call the frontend can use to
 *                                   populate stats + know if a claim is ready
 *
 * IMPORTANT HONESTY NOTE: saveScore() is self-reported by the player's client.
 * There's no way for a simple contract like this to verify a score was
 * legitimately earned in-game (that would need a server-signed message or a
 * ZK proof of the game's execution). Treat this as a fun on-chain leaderboard
 * / activity log, not a cheat-proof competitive ranking.
 */
contract BaseInvaders {
    struct PlayerStats {
        uint256 bestScore;
        uint256 bestWave;
        uint256 lastClaimTimestamp;
        uint256 totalClaims;
        uint256 currentStreak;
    }

    mapping(address => PlayerStats) public stats;

    uint256 public constant CLAIM_COOLDOWN = 24 hours;
    // If the player claims again within this window of their last claim,
    // their streak continues; otherwise it resets to 1.
    uint256 public constant STREAK_GRACE_WINDOW = 48 hours;

    event ScoreSaved(address indexed player, uint256 score, uint256 wave, uint256 timestamp);
    event DailyBoostClaimed(address indexed player, uint256 streak, uint256 totalClaims, uint256 timestamp);

    /// @notice Save a run's result. Only updates storage if it's a new personal best.
    function saveScore(uint256 score, uint256 wave) external {
        PlayerStats storage p = stats[msg.sender];
        if (score > p.bestScore) {
            p.bestScore = score;
            p.bestWave = wave;
        }
        emit ScoreSaved(msg.sender, score, wave, block.timestamp);
    }

    /// @notice Claim the once-per-24h daily boost. Reverts if still on cooldown.
    function claimDailyBoost() external {
        PlayerStats storage p = stats[msg.sender];
        require(
            block.timestamp >= p.lastClaimTimestamp + CLAIM_COOLDOWN,
            "Daily boost still on cooldown"
        );

        if (p.lastClaimTimestamp != 0 && block.timestamp <= p.lastClaimTimestamp + STREAK_GRACE_WINDOW) {
            p.currentStreak += 1;
        } else {
            p.currentStreak = 1;
        }

        p.lastClaimTimestamp = block.timestamp;
        p.totalClaims += 1;

        emit DailyBoostClaimed(msg.sender, p.currentStreak, p.totalClaims, block.timestamp);
    }

    /// @notice Convenience read for the frontend: everything it needs in one call.
    function getPlayerStats(address player)
        external
        view
        returns (
            uint256 bestScore,
            uint256 bestWave,
            uint256 lastClaimTimestamp,
            uint256 totalClaims,
            uint256 currentStreak,
            bool canClaimNow
        )
    {
        PlayerStats memory p = stats[player];
        return (
            p.bestScore,
            p.bestWave,
            p.lastClaimTimestamp,
            p.totalClaims,
            p.currentStreak,
            block.timestamp >= p.lastClaimTimestamp + CLAIM_COOLDOWN
        );
    }
}
