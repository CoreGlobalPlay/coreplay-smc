//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../Leaderboard/Leaderboard.sol";

contract Crash is AccessControl, Pausable {
    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant GAME_ID = 2;

    // -----------
    /// Storages
    // -----------
    uint256 public totalGame;
    address public leaderboard;

    // -----------
    // Events
    // -----------
    event Game(uint256 betAmount, uint256 fee, address user, bool isWin);

    constructor(address leaderboard_) {
        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ADMIN_ROLE, sender);

        leaderboard = leaderboard_;
    }

    function _calculateBetArray(
        uint256 multiplier
    ) public pure returns (uint256 winRate, uint256 totalRate) {
        // Extract the fractional part by multiplying the multiplier by 100 and getting the remainder
        uint256 fraction = multiplier % 100;

        // Determine the number of repetitions based on the fractional part
        if (fraction == 25) {
            winRate = 4;
        } else if (fraction == 50) {
            winRate = 2;
        } else if (fraction == 75) {
            winRate = 4; // Needs 4 repetitions to sum to a whole number
        } else {
            winRate = 1; // Whole numbers and zero fraction
        }

        // Calculate the total sum when the multiplier is used 'repeatMultiplier' times
        uint256 totalSum = multiplier * winRate;

        // Calculate the total number of elements needed (rounded up to ensure whole number)
        totalRate = (totalSum + 99) / 100; // Ceiling equivalent for total sum
    }

    // multiplier: 100 -> 10000 (x1 -> x100)
    function crash(uint256 multiplier) external payable whenNotPaused {
        // Validate must divisable to 25
        require(
            multiplier > 100 && multiplier < 10000 && multiplier % 25 == 0,
            "invalid multiplier"
        );

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();
        uint256 _rewardAmount = (multiplier * _betAmount) / 100;
        require(leaderboard.balance >= _rewardAmount, "house out of balance");
        totalGame = totalGame + 1;

        (uint256 winRate, uint256 totalRate) = _calculateBetArray(multiplier);

        // check result
        uint256 rand = getRandomUint();
        rand = rand % totalRate;

        bool isWin = rand < winRate;
        if (!isWin) {
            _rewardAmount = 0;
        }
        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            msg.sender,
            _rewardAmount,
            _betAmount
        );

        emit Game(_betAmount, fee, sender, isWin);
    }

    function setLeaderboard(address leaderboard_) public onlyRole(ADMIN_ROLE) {
        leaderboard = leaderboard_;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    receive() external payable {}

    function getRandomUint() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.number, totalGame, msg.sender))
            );
    }
}
