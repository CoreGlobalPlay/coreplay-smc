//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@coti-io/coti-contracts/contracts/utils/mpc/MpcCore.sol";
import "../Leaderboard/Leaderboard.sol";

contract Plinko is AccessControl, Pausable {
    // -----------
    /// Constants
    // -----------
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    uint256 private constant FEE_DENOMINATOR = 10_000;
    uint64 private constant DEGEN_LENGTH = 49;
    uint64 private constant BASIC_LENGTH = 66;
    uint256 private constant MAX_MULTIPLIER = 1500;
    uint256 public constant GAME_ID = 3;

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
    mapping(uint64 => uint256) public degenMultiplier;
    mapping(uint64 => uint256) public basicMultiplier;

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

        betFee = 350;
        minBet = 25 ether / 1_000; // 0.025
        maxBet = 2 ether; // 2
        govFee = 1 ether / 100_000; // 0.00001

        feeReceiver = sender;
        govAddress = sender;
        leaderboard = leaderboard_;

        // Degen
        degenMultiplier[43] = 200;
        degenMultiplier[44] = 200;
        degenMultiplier[45] = 1000;
        degenMultiplier[46] = 1000;
        degenMultiplier[47] = 1000;
        degenMultiplier[48] = 1500;

        // Basic
        for (uint64 i = 0; i < 48; i++) basicMultiplier[i] = 50;
        for (uint64 i = 48; i < 58; i++) basicMultiplier[i] = 150;
        for (uint64 i = 58; i < 65; i++) basicMultiplier[i] = 300;
        basicMultiplier[65] = 600;
    }

    function _calculateBetArray(
        uint64 multiplier
    ) public pure returns (uint64 winRate, uint64 totalRate) {
        // Extract the fractional part by multiplying the multiplier by 100 and getting the remainder
        uint64 fraction = multiplier % 100;

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
        uint64 totalSum = multiplier * winRate;

        // Calculate the total number of elements needed (rounded up to ensure whole number)
        totalRate = (totalSum + 99) / 100; // Ceiling equivalent for total sum
    }

    function plinko(bool degen, uint256 ball) external payable whenNotPaused {
        address sender = _msgSender();
        // take fee
        uint256 _betAmountBeforeFee = msg.value - (ball * govFee);
        uint256 _betAmount = (_betAmountBeforeFee * FEE_DENOMINATOR) /
            (FEE_DENOMINATOR + betFee) /
            ball;
        require(_betAmount >= minBet && _betAmount <= maxBet, "invalid bet");

        uint256 fee = _betAmountBeforeFee - (_betAmount * ball);
        totalGame += ball;

        payable(govAddress).transfer(govFee);
        payable(feeReceiver).transfer(fee);

        uint256 maxRewardAmount = (ball * (MAX_MULTIPLIER * _betAmount)) / 100;
        require(
            address(this).balance >= maxRewardAmount,
            "house out of balance"
        );

        uint64 totalRate = degen ? DEGEN_LENGTH : BASIC_LENGTH;

        // check result
        uint totalRewardAmount = 0;
        uint64 rand = MpcCore.decrypt(MpcCore.rand64());
        for (uint64 i = 0; i < ball; i++) {
            uint64 randIndex = (rand * (i + 1)) % totalRate;

            uint256 multiplier = degen
                ? degenMultiplier[randIndex]
                : basicMultiplier[randIndex];
            uint rewardAmount = (multiplier * _betAmount) / 100;
            totalRewardAmount += rewardAmount;
            emit Game(_betAmount, fee, sender, multiplier, rewardAmount);
        }

        if (totalRewardAmount > 0) {
            payable(sender).transfer(totalRewardAmount);
        }

        Leaderboard(leaderboard).newPoint(
            GAME_ID,
            msg.sender,
            totalRewardAmount - msg.value,
            _betAmount * ball
        );
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

    function withdrawAll(address addr) external onlyRole(WITHDRAWER) {
        address payable _to = payable(addr);
        _to.transfer(address(this).balance);
    }

    function withdraw(
        address addr,
        uint256 amount
    ) external onlyRole(WITHDRAWER) {
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
}
