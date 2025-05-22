//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Leaderboard/Leaderboard.sol";
import { SwResolver } from "../SwResolver.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Mines is UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SwResolver {

    // -----------
    /// Structs
    // -----------
    struct BetInfo {
        address user;
        uint256 mines;
        uint256 level;
        uint256 betAmount;
    }

    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint64 public constant GRID_SIZE = 16;
    uint256 public constant GAME_ID = 4;

    // -----------
    /// Storages
    // -----------
    uint256 public totalGame;
    address public leaderboard;
    mapping(uint256 => BetInfo) public gameIdToBetInfo;

    // -----------
    // Events
    // -----------
    event NewBet(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 mines, uint256 level, uint256 fee);
    event Game(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 mines, uint256 level, uint256 payout);

    function initialize(address leaderboard_, address switchboard_, bytes32 swQueue_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        leaderboard = leaderboard_;
        setupResolver(switchboard_, swQueue_);
    }

    function _calculateBetArray(
        uint256 mines,
        uint256 level
    )
        public
        pure
        returns (uint256 winRate, uint256 totalRate, uint256 multiplier)
    {
        totalRate = GRID_SIZE - level;
        winRate = totalRate - mines;
        multiplier = uint256((totalRate * 100) / (totalRate - mines));
    }

    function checkMine(
        uint256 mines,
        uint256 level
    ) external payable whenNotPaused {
        require(
            mines == 1 ||
                mines == 3 ||
                mines == 5 ||
                mines == 10 ||
                mines == 15,
            "invalid mines"
        );
        require(mines <= GRID_SIZE - level, "Mines exceed remaining cells");

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();

        uint256 gameId = totalGame;
        requestRandomNumber(gameId);
        BetInfo memory betInfo = BetInfo({
            user: sender,
            mines: mines,
            level: level,
            betAmount: _betAmount
        });
        gameIdToBetInfo[totalGame] = betInfo;

        totalGame = gameId + 1;

        // New Bet
        emit NewBet(sender, gameId, _betAmount, mines, level, fee);
    }

    // handle entropy callback
    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal override whenNotPaused {
        BetInfo storage betInfo = gameIdToBetInfo[gameId];
        uint256 mines = betInfo.mines;
        uint256 level = betInfo.level;
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

        (
            uint256 winRate,
            uint256 totalRate,
            uint256 multiplier
        ) = _calculateBetArray(mines, level);

        // check result
        uint256 rand = randomNumber % totalRate;

        uint256 rewardAmount = (multiplier * betAmount) / 100;

        bool isWin = rand < winRate;
        if (!isWin) {
            rewardAmount = 0;
            multiplier = 0;
        }
        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            user,
            rewardAmount,
            betAmount
        );

        emit Game(user, gameId, betAmount, mines, level, rewardAmount);
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

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}
}
