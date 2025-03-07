//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../Leaderboard/Leaderboard.sol";

contract Crash is AccessControl, Pausable {
    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private constant FEE_DENOMINATOR = 10_000;
    uint256 public constant GAME_ID = 2;

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
    event Game(uint256 betAmount, uint256 fee, address user, bool isWin);

    constructor(address leaderboard_) {
        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ADMIN_ROLE, sender);

        betFee = 350;
        minBet = 25 ether / 10_000; // 0.0025
        maxBet = 2 ether / 10; // 0.2
        govFee = 1 ether / 1_000_000; // 0.000001

        feeReceiver = sender;
        govAddress = sender;
        leaderboard = leaderboard_;
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
            "invalid multiplier"
        );

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

        uint256 _rewardAmount = (multiplier * _betAmount) / 100;
        require(address(this).balance >= _rewardAmount, "house out of balance");

        (uint256 winRate, uint256 totalRate) = _calculateBetArray(multiplier);

        // check result
        uint256 rand = getRandomUint();
        rand = rand % totalRate;

        bool isWin = rand < winRate;
        if (isWin) {
            payable(sender).transfer(_rewardAmount);
        }

        uint256 earnAmount = 0;
        if (_rewardAmount > msg.value) {
            earnAmount = _rewardAmount - msg.value;
        }
        Leaderboard(leaderboard).newPoint(
            GAME_ID,
            msg.sender,
            earnAmount,
            _betAmount
        );

        emit Game(_betAmount, fee, sender, isWin);
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
                        totalGame,
                        msg.sender
                    )
                )
            );
    }
}
