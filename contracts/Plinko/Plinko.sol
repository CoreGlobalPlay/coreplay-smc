//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../Leaderboard/Leaderboard.sol";

contract Plinko is AccessControl, Pausable {
    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private constant DEGEN_LENGTH = 49;
    uint256 private constant BASIC_LENGTH = 66;
    uint256 private constant MAX_MULTIPLIER = 1500;
    uint256 public constant GAME_ID = 3;

    // -----------
    /// Storages
    // -----------
    uint256 public totalGame;
    address public leaderboard;
    mapping(uint256 => uint256) public degenMultiplier;
    mapping(uint256 => uint256) public basicMultiplier;

    // -----------
    // Events
    // -----------
    event Game(
        uint256 betAmount,
        uint256 fee,
        address user,
        uint256 multiplier,
        uint256 rewardAmount
    );

    constructor(address leaderboard_) {
        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ADMIN_ROLE, sender);

        leaderboard = leaderboard_;

        // Degen
        degenMultiplier[43] = 200;
        degenMultiplier[44] = 200;
        degenMultiplier[45] = 1000;
        degenMultiplier[46] = 1000;
        degenMultiplier[47] = 1000;
        degenMultiplier[48] = 1500;

        // Basic
        for (uint256 i = 0; i < 48; i++) basicMultiplier[i] = 50;
        for (uint256 i = 48; i < 58; i++) basicMultiplier[i] = 150;
        for (uint256 i = 58; i < 65; i++) basicMultiplier[i] = 300;
        basicMultiplier[65] = 600;
    }

    function plinko(bool degen, uint256 ball) external payable whenNotPaused {
        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();
        uint256 maxRewardAmount = (ball * (MAX_MULTIPLIER * _betAmount)) / 100;
        require(leaderboard.balance >= maxRewardAmount, "house out of balance");
        totalGame += ball;

        uint256 totalRate = degen ? DEGEN_LENGTH : BASIC_LENGTH;

        // check result
        uint totalRewardAmount = 0;
        for (uint256 i = 0; i < ball; i++) {
            uint256 rand = getRandomUint(i);
            uint256 randIndex = rand % totalRate;

            uint256 multiplier = degen
                ? degenMultiplier[randIndex]
                : basicMultiplier[randIndex];
            uint rewardAmount = (multiplier * _betAmount) / 100;
            totalRewardAmount += rewardAmount;
            emit Game(_betAmount, fee, sender, multiplier, rewardAmount);
        }

        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            msg.sender,
            totalRewardAmount,
            _betAmount * ball
        );
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

    function getRandomUint(uint256 i) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.number, totalGame, msg.sender, i)
                )
            );
    }
}
