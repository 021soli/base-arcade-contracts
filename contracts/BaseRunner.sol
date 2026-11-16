// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Base Runner — onchain distance tracker + daily check-in
/// @notice Matches the CONTRACT_ABI already wired into the game's index.html:
///         claimDailyRun(uint256), dailyCheckIn(), bestDistanceOf(address),
///         lastCheckInOf(address). No tokens, no ETH transfers — just state.
contract BaseRunner {
    struct PlayerStats {
        uint256 bestDistance;   // meters, self-reported best run
        uint256 lastCheckIn;    // unix timestamp of last daily check-in
        uint256 totalCheckIns;
        uint256 totalClaims;
    }

    mapping(address => PlayerStats) public stats;

    uint256 public constant CHECK_IN_COOLDOWN = 1 days;

    event DailyRunClaimed(address indexed player, uint256 distanceMeters, uint256 timestamp);
    event DailyCheckIn(address indexed player, uint256 timestamp, uint256 totalCheckIns);

    /// @notice Records this run's distance if it beats your onchain best.
    /// @dev Self-reported (no server-side proof of actual gameplay) — fine for
    /// a fun onchain leaderboard, not meant to be tamper-proof.
    function claimDailyRun(uint256 distanceMeters) external {
        PlayerStats storage s = stats[msg.sender];
        if (distanceMeters > s.bestDistance) {
            s.bestDistance = distanceMeters;
        }
        s.totalClaims += 1;
        emit DailyRunClaimed(msg.sender, distanceMeters, block.timestamp);
    }

    /// @notice Once-per-24h check-in, independent of claimDailyRun.
    function dailyCheckIn() external {
        PlayerStats storage s = stats[msg.sender];
        require(
            block.timestamp >= s.lastCheckIn + CHECK_IN_COOLDOWN,
            "BaseRunner: check-in still on cooldown"
        );
        s.lastCheckIn = block.timestamp;
        s.totalCheckIns += 1;
        emit DailyCheckIn(msg.sender, block.timestamp, s.totalCheckIns);
    }

    /// @notice Matches bestDistanceOf(address) in the game's ABI.
    function bestDistanceOf(address player) external view returns (uint256) {
        return stats[player].bestDistance;
    }

    /// @notice Matches lastCheckInOf(address) in the game's ABI.
    function lastCheckInOf(address player) external view returns (uint256) {
        return stats[player].lastCheckIn;
    }

    /// @notice Convenience getter — seconds until this player can check in again (0 if now).
    function timeUntilNextCheckIn(address player) external view returns (uint256) {
        uint256 nextCheckIn = stats[player].lastCheckIn + CHECK_IN_COOLDOWN;
        if (block.timestamp >= nextCheckIn) return 0;
        return nextCheckIn - block.timestamp;
    }
}
