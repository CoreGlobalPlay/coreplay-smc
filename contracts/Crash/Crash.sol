//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../Leaderboard/Leaderboard.sol";
import { SwResolver } from "../SwResolver.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Crash is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SwResolver {
    // -----------
    /// Structs
    // -----------
    struct BetInfo {
        address user;
        uint256 betAmount;
        uint256 multiplier;
    }

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
    mapping(uint256 => BetInfo) public gameIdToBetInfo;

    // -----------
    // Events
    // -----------
    event NewBet(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 multiplier, uint256 fee);
    event Game(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 multiplier, uint256 payout);

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
            "invalid cashOut"
        );

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();
        
        // push bet info
        uint256 gameId = totalGame + 1;
        BetInfo memory betInfo = BetInfo({
            user: sender,
            betAmount: _betAmount,
            multiplier: multiplier
        });
        gameIdToBetInfo[gameId] = betInfo;
        totalGame = gameId;
        requestRandomNumber(gameId);

        // New Bet
        emit NewBet(sender, gameId, _betAmount, multiplier, fee);
    }

    // handle entropy callback
    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal override whenNotPaused {
        BetInfo storage betInfo = gameIdToBetInfo[gameId];
        uint256 multiplier = betInfo.multiplier;
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
        
        /// calculate rate
        (uint256 winRate, uint256 totalRate) = _calculateBetArray(multiplier);

        // check result
        uint256 rand = randomNumber % totalRate;

        bool isWin = rand < winRate;

        // check if win
        uint256 _rewardAmount = betAmount * multiplier;
        if (!isWin) {
            _rewardAmount = 0;
        }

        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            user,
            _rewardAmount,
            betAmount
        );
        emit Game(user, gameId, betAmount, multiplier, _rewardAmount);


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
