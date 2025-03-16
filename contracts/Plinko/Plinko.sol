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
        uint256 rand = getRandomUint();
        for (uint256 i = 0; i < ball; i++) {
            uint256 randIndex = (rand * (i + 1)) % totalRate;

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

    function getRandomUint() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.number, totalGame, msg.sender))
            );
    }
}
