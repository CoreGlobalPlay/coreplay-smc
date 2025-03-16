//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../Leaderboard/Leaderboard.sol";

contract CoinFlip is AccessControl, Pausable {
    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant GAME_ID = 1;

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

    function flip(bool gtSide) external payable whenNotPaused {
        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();
        uint256 _rewardAmount = 2 * _betAmount;
        require(leaderboard.balance >= _rewardAmount, "house out of balance");

        totalGame = totalGame + 1;

        // check result
        bool gtResult = getRandomBool();
        bool isWin = gtResult == gtSide;

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

    function getRandomBool() internal view returns (bool) {
        uint256 randomHash = uint256(
            keccak256(abi.encodePacked(block.number, totalGame, msg.sender))
        );
        return randomHash % 2 == 0;
    }
}
