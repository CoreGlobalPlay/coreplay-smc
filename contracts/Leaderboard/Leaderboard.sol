// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Leaderboard is 
    UUPSUpgradeable,
    AccessControlUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    uint256 private constant FEE_DENOMINATOR = 10_000;

    //////////////
    /// Storage
    //////////////
    mapping(address => uint256) public points;
    mapping(address => uint256) public pendingReward;
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
    event ClaimReward(address user, uint256 amount);

    //////////////
    /// Constructor
    //////////////
    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init();

        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(ADMIN_ROLE, sender);
        _grantRole(GAME_ROLE, sender);
        _grantRole(WITHDRAWER, sender);

        betFee = 350;
        minBet = 5 ether / 10; // 0.5
        maxBet = 40 ether; // 40
        govFee = 2 ether / 1_000; // 0.002

        feeReceiver = sender;
        govAddress = sender;
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

    function takeFeeWithAttemp(uint256 attempts) public payable returns (uint256 betAmount, uint256 fee) {
        uint256 _betAmountBeforeFee = msg.value - govFee;
        betAmount =
            (_betAmountBeforeFee * FEE_DENOMINATOR) /
            (FEE_DENOMINATOR + betFee);
        require(betAmount >= minBet*attempts && betAmount <= maxBet*attempts, "invalid bet");

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
        (bool success, ) = payable(addr).call{value: address(this).balance}("");
        require(success, "transfer failed");
        
        emit Withdraw(msg.sender, address(this).balance);
    }

    function withdraw(
        address addr,
        uint256 amount
    ) external onlyRole(WITHDRAWER) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "invalid amount");

        (bool success, ) = payable(addr).call{value: amount}("");
        require(success, "transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function earnReward(
        uint256 gameId,
        address user,
        uint256 earnAmount,
        uint256 betAmount
    ) external onlyRole(GAME_ROLE) {
        if (earnAmount > 0) {
            pendingReward[user] += earnAmount;
            if (earnAmount > betAmount) {
                points[user] += (earnAmount - betAmount);
                emit NewPoint(gameId, user, earnAmount, betAmount);
            }
        }
    }

    function claimReward() external {
        uint256 earnAmount = pendingReward[_msgSender()];
        require(earnAmount > 0, "no reward");
        pendingReward[_msgSender()] = 0;

        (bool success, ) = payable(_msgSender()).call{value: earnAmount}("");
        require(success, "transfer failed");

        emit ClaimReward(_msgSender(), earnAmount);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}
}
