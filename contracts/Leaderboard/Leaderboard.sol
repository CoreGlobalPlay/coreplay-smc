// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Leaderboard is AccessControl {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    uint256 private constant FEE_DENOMINATOR = 10_000;

    //////////////
    /// Storage
    //////////////
    mapping(address => uint256) public points;
    uint256 public betFee;
    uint256 public minBet;
    uint256 public maxBet;
    address public feeReceiver;
    uint256 public govFee;
    address public govAddress;

    //////////////
    /// Events
    //////////////
    event NewPoint(
        uint256 gameId,
        address user,
        uint256 earnAmount,
        uint256 betAmount
    );
    event Withdraw(address user, uint256 amount);
    event Deposit(address user, uint256 amount);

    //////////////
    /// Constructor
    //////////////
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GAME_ROLE, msg.sender);
        _grantRole(WITHDRAWER, msg.sender);

        betFee = 350;
        minBet = 25 ether / 100_000; // 0.00025
        maxBet = 2 ether / 100; // 0.02
        govFee = 1 ether / 1_000_000; // 0.000001

        feeReceiver = msg.sender;
        govAddress = msg.sender;
    }

    function takeFee() public payable returns (uint256 betAmount, uint256 fee) {
        uint256 _betAmountBeforeFee = msg.value - govFee;
        betAmount =
            (_betAmountBeforeFee * FEE_DENOMINATOR) /
            (FEE_DENOMINATOR + betFee);
        require(betAmount >= minBet && betAmount <= maxBet, "invalid bet");

        fee = _betAmountBeforeFee - betAmount;

        payable(govAddress).transfer(govFee);
        payable(feeReceiver).transfer(fee);
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
        emit Withdraw(msg.sender, address(this).balance);
    }

    function withdraw(
        address addr,
        uint256 amount
    ) external onlyRole(WITHDRAWER) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "invalid amount");
        address payable _to = payable(addr);
        _to.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function earnReward(
        uint256 gameId,
        address user,
        uint256 earnAmount,
        uint256 betAmount
    ) external onlyRole(GAME_ROLE) {
        if (earnAmount > 0) {
            payable(user).transfer(earnAmount);
            if (earnAmount > betAmount) {
                points[user] += (earnAmount - betAmount);
                emit NewPoint(gameId, user, earnAmount, betAmount);
            }
        }
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
}
