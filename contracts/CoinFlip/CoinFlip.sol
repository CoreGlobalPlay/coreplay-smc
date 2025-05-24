//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { SwResolver } from "../SwResolver.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../Leaderboard/Leaderboard.sol";

contract CoinFlip is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SwResolver {
    // -----------
    /// Structs
    // -----------
    struct BetInfo {
        address user;
        bool side;
        uint256 betAmount;
    }

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
    mapping(uint256 => BetInfo) public gameIdToBetInfo;

    // -----------
    // Events
    // -----------
    event NewBet(address indexed user, uint256 indexed gameId, uint256 betAmount, bool side, uint256 fee);
    event Game(address indexed user, uint256 indexed gameId, uint256 betAmount, bool side, uint256 payout);

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

    function flip(bool side) external payable whenNotPaused {

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();

        uint256 gameId = totalGame + 1;
        requestRandomNumber(gameId);
        BetInfo memory betInfo = BetInfo({
            user: sender,
            side: side,
            betAmount: _betAmount
        });
        gameIdToBetInfo[gameId] = betInfo;

        totalGame = gameId;

        // New Bet
        emit NewBet(sender, gameId, _betAmount, side, fee);
    }

    // handle entropy callback
    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal override whenNotPaused {
        BetInfo storage betInfo = gameIdToBetInfo[gameId];
        bool selectedSide = betInfo.side;
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

        bool result = randomNumber % 2 == 0;
        bool isWin = result == selectedSide;

        uint256 _rewardAmount = 2 * betAmount;

        if (isWin) {
            Leaderboard(leaderboard).earnReward(
                GAME_ID,
                user,
                _rewardAmount,
                betAmount
            );
        } else {
            _rewardAmount = 0;
        }

        emit Game(user, gameId, betAmount, selectedSide, _rewardAmount);
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
