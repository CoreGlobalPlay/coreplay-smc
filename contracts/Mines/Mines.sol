//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../Leaderboard/Leaderboard.sol";

contract Mines is AccessControl, Pausable {
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

    // -----------
    // Events
    // -----------
    event Game(
        uint256 betAmount,
        uint256 fee,
        address user,
        uint256 reward,
        uint256 multiplier
    );

    constructor(address leaderboard_) {
        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ADMIN_ROLE, sender);

        leaderboard = leaderboard_;
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

        (
            uint256 winRate,
            uint256 totalRate,
            uint256 multiplier
        ) = _calculateBetArray(mines, level);
        uint256 _rewardAmount = (multiplier * _betAmount) / 100;
        require(leaderboard.balance >= _rewardAmount, "house out of balance");
        totalGame = totalGame + 1;

        // check result
        uint256 rand = getRandomUint();
        rand = rand % totalRate;

        bool isWin = rand < winRate;
        if (!isWin) {
            _rewardAmount = 0;
            multiplier = 0;
        }
        Leaderboard(leaderboard).earnReward(
            GAME_ID,
            msg.sender,
            _rewardAmount,
            _betAmount
        );

        emit Game(_betAmount, fee, sender, _rewardAmount, multiplier);
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
