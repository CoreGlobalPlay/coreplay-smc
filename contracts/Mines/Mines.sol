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
    uint256 private constant FEE_DENOMINATOR = 10_000;
    uint256 public constant GRID_SIZE = 16;
    uint256 public constant GAME_ID = 4;

    // -----------
    /// Storages
    // -----------
    uint256 public totalGame;
    uint256 public betFee;
    uint256 public minBet;
    uint256 public maxBet;
    address public feeReceiver;
    uint256 public govFee;
    address public govAddress;
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

        betFee = 350;
        minBet = 25 ether / 10_000; // 0.0025
        maxBet = 2 ether / 10; // 0.2
        govFee = 1 ether / 1_000_000; // 0.00001

        feeReceiver = sender;
        govAddress = sender;
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
        uint256 _betAmountBeforeFee = msg.value - govFee;
        uint256 _betAmount = (_betAmountBeforeFee * FEE_DENOMINATOR) /
            (FEE_DENOMINATOR + betFee);
        require(_betAmount >= minBet && _betAmount <= maxBet, "invalid bet");

        uint256 fee = _betAmountBeforeFee - _betAmount;
        totalGame = totalGame + 1;

        payable(govAddress).transfer(govFee);
        payable(feeReceiver).transfer(fee);

        (
            uint256 winRate,
            uint256 totalRate,
            uint256 multiplier
        ) = _calculateBetArray(mines, level);

        uint256 _rewardAmount = (multiplier * _betAmount) / 100;
        require(address(this).balance >= _rewardAmount, "house out of balance");

        // check result
        uint256 rand = getRandomUint();
        rand = rand % totalRate;

        bool isWin = rand < winRate;
        uint256 earnAmount = 0;
        if (isWin) {
            payable(sender).transfer(_rewardAmount);
            earnAmount = _rewardAmount - msg.value;
        } else {
            _rewardAmount = 0;
            multiplier = 0;
        }
        Leaderboard(leaderboard).newPoint(
            GAME_ID,
            msg.sender,
            earnAmount,
            _betAmount
        );

        emit Game(_betAmount, fee, sender, _rewardAmount, multiplier);
    }

    function setBetFee(uint256 val) public onlyRole(ADMIN_ROLE) {
        betFee = val;
    }

    function setMinBet(uint256 val) public onlyRole(ADMIN_ROLE) {
        require(val <= maxBet, "invalid bet");
        minBet = val;
    }

    function setMaxBet(uint256 val) public onlyRole(ADMIN_ROLE) {
        require(val >= minBet, "invalid bet");
        maxBet = val;
    }

    function setGovFee(uint256 val) public onlyRole(ADMIN_ROLE) {
        govFee = val;
    }

    function setFeeReceiver(address receiver) public onlyRole(ADMIN_ROLE) {
        feeReceiver = receiver;
    }

    function setGovAddress(address gov) public onlyRole(ADMIN_ROLE) {
        govAddress = gov;
    }

    function withdrawAll(address addr) external onlyRole(ADMIN_ROLE) {
        address payable _to = payable(addr);
        _to.transfer(address(this).balance);
    }

    function withdraw(
        address addr,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "invalid amount");
        address payable _to = payable(addr);
        _to.transfer(amount);
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
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender
                    )
                )
            );
    }
}
