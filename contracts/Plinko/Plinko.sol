//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Leaderboard/Leaderboard.sol";
import { SwResolver } from "../SwResolver.sol";
import {Structs} from "@switchboard-xyz/on-demand-solidity/structs/Structs.sol";
import {ISwitchboard} from "@switchboard-xyz/on-demand-solidity/ISwitchboard.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Plinko is UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SwResolver {

    // -----------
    /// Structs
    // -----------
    struct BetInfo {
        address user;
        bool degen;
        uint256 balls;
        uint256 betAmount;
    }

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
    mapping(uint256 => BetInfo) public gameIdToBetInfo;

    // -----------
    // Events
    // -----------
    event NewBet(address indexed user, uint256 indexed gameId, uint256 totalBetAmount, uint256 balls, uint256 fee);
    event Game(address indexed user, uint256 indexed gameId, uint256 totalBetAmount, uint256 balls, uint256 payout);
    event Ball(uint256 indexed gameId, uint256 multiplier);

    function initialize(address leaderboard_, address switchboard_, bytes32 swQueue_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();

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

        // Setup VRF
        setupResolver(switchboard_, swQueue_);
    }

    function plinko(bool degen, uint256 balls) external payable whenNotPaused {

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();

        uint256 gameId = totalGame;
        requestRandomNumber(gameId);
        BetInfo memory betInfo = BetInfo({
            user: sender,
            degen: degen,
            balls: balls,
            betAmount: _betAmount
        });
        gameIdToBetInfo[totalGame] = betInfo;

        totalGame = gameId + 1;

        // New Bet
        emit NewBet(sender, gameId, _betAmount, balls, fee);
    }

    // handle entropy callback
    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal override whenNotPaused {
        BetInfo storage betInfo = gameIdToBetInfo[gameId];
        uint256 balls = betInfo.balls;
        bool degen = betInfo.degen;
        uint256 betAmount = betInfo.betAmount;
        address user = betInfo.user;

        if (
            betAmount == 0
        ) {
            // The game is ended
            return;
        }
        // Set bet amount to zero to prevent re-entrancy
        betInfo.betAmount = 0;

        uint256 totalRate = degen ? DEGEN_LENGTH : BASIC_LENGTH;

        // check result
        uint totalRewardAmount = 0;
        uint256 betEachBall = betAmount / balls;
        for (uint256 i = 0; i < balls; i++) {
            uint256 rand = getRandomUint(randomNumber + i);
            uint256 randIndex = rand % totalRate;

            uint256 multiplier = degen
                ? degenMultiplier[randIndex]
                : basicMultiplier[randIndex];
            uint rewardAmount = (multiplier * betEachBall) / 100;
            totalRewardAmount += rewardAmount;
            emit Ball(gameId, multiplier);
        }
        emit Game(user, gameId, betAmount, balls, totalRewardAmount);

        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            user,
            totalRewardAmount,
            betAmount
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

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}
}
