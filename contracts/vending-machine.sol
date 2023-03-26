// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VendingMachine is ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public owner; 
    address public USDCAddress; 
    address public tokenAddress; 

    uint256 public TokenToUSDCRate;
    uint256 public minimumPurchaseAmount;

    AggregatorV3Interface internal priceFeedUSDC;
    AggregatorV3Interface internal priceFeedMATIC;
   
    constructor(address _USDCAddress, 
                uint256 _TokenToUSDCRate, 
                address _tokenAddress, 
                uint256 _minimumPurchaseAmount, 
                address _priceFeedUSDC, 
                address _priceFeedMATIC) {
        owner = msg.sender;
        
        USDCAddress = _USDCAddress;
        TokenToUSDCRate = _TokenToUSDCRate;
        tokenAddress = _tokenAddress;
        minimumPurchaseAmount = _minimumPurchaseAmount;

        priceFeedUSDC = AggregatorV3Interface(_priceFeedUSDC);
        priceFeedMATIC = AggregatorV3Interface(_priceFeedMATIC);
    }

    event Transfer(
        address from,
        address to,
        uint256 amount
    );

    event Convertation(
        uint256 tokenValue,
        uint256 USDCValue
    );

    function getLatestUSDCPrice() public view returns (int256) {
    (
        ,
        int price,
        ,
        ,
        
    ) = priceFeedUSDC.latestRoundData();
        return price;
    }

    function getLatestMATICPrice() public view returns (int256) {
    (
        ,
        int price,
        ,
        ,
        
    ) = priceFeedMATIC.latestRoundData();
        return price;
    }

    function convertToUSDC(uint256 _TokenAmount) public view returns (uint256) {
        return _TokenAmount.mul(TokenToUSDCRate) / 10**14; 
    }

    function convertFromUSDC(uint256 USDC) public view returns (uint256) {
        return (USDC * 100 / TokenToUSDCRate) * 10**12; 
    }

    function getVendingMATICBalance() public view returns(uint256) {
        return address(this).balance;
    }

    modifier checkPurchaseAmount(uint256 _TokenAmount){
        require(_TokenAmount >= minimumPurchaseAmount, "Minimum purchase amount is greater than input amount");
        _;
    }

    modifier sufficientTokenFunds(address fundsOwner, uint256 _TokenAmount){
        IERC20 TOKEN = IERC20(tokenAddress);
        require(TOKEN.balanceOf(fundsOwner) >= _TokenAmount, "Insufficient funds in ERC20");
        _;
    }

    function purchaseForUSDC(uint256 _TokenAmount) public payable checkPurchaseAmount(_TokenAmount) sufficientTokenFunds(address(this), _TokenAmount) returns (uint256 spentAmount) {
        uint256 _USDCAmount = convertToUSDC(_TokenAmount);
        emit Convertation(_TokenAmount, _USDCAmount);

        IERC20 USDC = IERC20(USDCAddress);
        IERC20 TOKEN = IERC20(tokenAddress);

        require(USDC.balanceOf(msg.sender) >= _USDCAmount, "Insufficient funds in USDC");
        require(USDC.allowance(msg.sender, address(this)) >= _USDCAmount, "Insufficient allowance in USDC");

        USDC.safeTransferFrom(msg.sender, address(this), _USDCAmount);
        emit Transfer(msg.sender, address(this), _USDCAmount);

        TOKEN.safeTransfer(msg.sender, _TokenAmount);
        emit Transfer(address(this), msg.sender, _TokenAmount);

        return _USDCAmount;
    }

    function purchaseForMATIC() public payable returns (uint256 boughtAmount) {
        uint256 _USDCAmount = uint256(uint256(getLatestMATICPrice() / getLatestUSDCPrice()) * msg.value) / 10**12;
        uint256 _TokenAmount = convertFromUSDC(_USDCAmount);

        require(_TokenAmount >= minimumPurchaseAmount, "Minimum purchase amount is greater than input amount");
        emit Convertation(_TokenAmount, _USDCAmount);
        
        IERC20 TOKEN = IERC20(tokenAddress);

        require(TOKEN.balanceOf(address(this)) >= _TokenAmount, "Insufficient funds in the Vending contract");

        TOKEN.safeTransfer(msg.sender, _TokenAmount);
        emit Transfer(address(this), msg.sender, _TokenAmount);

        return _TokenAmount;
    }

    function withdraw(uint256 _TokenAmount) public payable nonReentrant sufficientTokenFunds(msg.sender, _TokenAmount) returns (uint256 withdrawnAmount) {
        uint256 _USDCAmount = convertToUSDC(_TokenAmount);
        emit Convertation(_TokenAmount, _USDCAmount);
        
        IERC20 USDC = IERC20(USDCAddress);
        IERC20 TOKEN = IERC20(tokenAddress);

        require(USDC.balanceOf(address(this)) >= _USDCAmount, "Insufficient funds in the Vending contract");
        require(TOKEN.allowance(msg.sender, address(this)) >= _TokenAmount, "Insufficient allowance in ERC20");

        TOKEN.safeTransferFrom(msg.sender, address(this), _TokenAmount);
        emit Transfer(msg.sender, address(this), _TokenAmount);
       
        USDC.safeTransfer(msg.sender, _USDCAmount );
        emit Transfer(address(this), msg.sender, _USDCAmount);

        return _USDCAmount;
    }

    function withdrawMatic(uint256 _TokenAmount) public payable nonReentrant sufficientTokenFunds(msg.sender, _TokenAmount) returns (uint256 withdrawnAmount) {
        
        uint256 _MATICAmount =  (convertToUSDC(_TokenAmount) * 10**20) / uint256(getLatestMATICPrice()) ;
        emit Convertation(_TokenAmount, _MATICAmount);

        IERC20 TOKEN = IERC20(tokenAddress);

        require(TOKEN.allowance(msg.sender, address(this)) >= _TokenAmount, "Insufficient funds in ERC20");
        require(getVendingMATICBalance() >= _MATICAmount, "Insufficient funds in MATIC");

        TOKEN.safeTransferFrom(msg.sender, address(this), _TokenAmount);
        emit Transfer(msg.sender, address(this), _TokenAmount);

        payable(msg.sender).transfer(_MATICAmount);
        emit Transfer(address(this), msg.sender, _MATICAmount);

        return _MATICAmount;
    }

}
