//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
        uint256 cashOut;
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
    BetInfo[] public bets;

    // -----------
    // Events
    // -----------
    event NewGame(uint256 newGameId, uint256 maxCashOutToWin);
    event NewBet(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 cashOut, uint256 fee);
    event Game(address indexed user, uint256 indexed gameId, uint256 betAmount, uint256 cashOut, uint256 payout);

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

    // cashOut = multiplier: 100 -> 10000 (x1 -> x100)
    function bet(uint256 cashOut) external payable whenNotPaused {
        // Validate must divisable to 25
        require(
            cashOut > 100 && cashOut < 10000 && cashOut % 25 == 0,
            "invalid cashOut"
        );

        address sender = _msgSender();
        // take fee
        (uint256 _betAmount, uint256 fee) = Leaderboard(leaderboard).takeFee{
            value: msg.value
        }();
        
        // push bet info
        BetInfo memory betInfo = BetInfo({
            user: sender,
            betAmount: _betAmount,
            cashOut: cashOut
        });
        bets.push(betInfo);

        // New Bet
        emit NewBet(sender, totalGame, _betAmount, cashOut, fee);
    }

    // handle entropy callback
    function handleRandomNumber(
        uint256 gameId,
        uint256 randomNumber
    ) internal override whenNotPaused {
        if (
            gameId != totalGame
        ) {
            // This is not the game we are looking for
            // Cannot use require because we ensure the callback cannot be failed
            return;
        }

        uint256 maxCashOutToWin = 100;
        uint256 minCashOutToLose = 10000;

        for (uint256 i = 0; i < bets.length; i++) {
            BetInfo storage betInfo = bets[i];
            uint256 cashOut = betInfo.cashOut;
            uint256 betAmount = betInfo.betAmount;
            address user = betInfo.user;

            uint256 _rewardAmount = (cashOut * betAmount) / 100;

            // win
            if (cashOut <= maxCashOutToWin) {
                Leaderboard(leaderboard).earnReward(
                    GAME_ID,
                    user,
                    _rewardAmount,
                    betAmount
                );
                emit Game(user, gameId, betAmount, cashOut, _rewardAmount);
                continue;
            }

            // lose
            if (cashOut >= minCashOutToLose) {
                emit Game(user, gameId, betAmount, cashOut, 0);
                continue;
            }  

            /// calculate rate
            (uint256 winRate, uint256 totalRate) = _calculateBetArray(cashOut);

            // check result
            uint256 rand = randomNumber % totalRate;

            bool isWin = rand < winRate;

            // check if win
            if (!isWin) {
                _rewardAmount = 0;
                // all cashout bigger than this will be lost
                minCashOutToLose = cashOut;
            } else {
                // all cashout lower than this will be win
                maxCashOutToWin = cashOut;
            }

            Leaderboard(leaderboard).earnReward(
                GAME_ID,
                user,
                _rewardAmount,
                betAmount
            );
            emit Game(user, gameId, betAmount, cashOut, _rewardAmount);
        }

        totalGame = totalGame + 1;
        delete bets;

        emit NewGame(totalGame, maxCashOutToWin);
    }

    function setLeaderboard(address leaderboard_) public onlyRole(ADMIN_ROLE) {
        leaderboard = leaderboard_;
    }

    function launch() external payable whenNotPaused {
        if (bets.length > 0) {
            requestRandomNumber(totalGame);
        } else {
            totalGame = totalGame + 1;
            emit NewGame(totalGame, 100);
        }
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
