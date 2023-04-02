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
    address public USDTAddress;
    address public ERC20Address;

    uint256 public ERC20ToUSDCRate;
    uint256 public minimumPurchaseAmount;

    AggregatorV3Interface internal priceFeedUSDC;
    AggregatorV3Interface internal priceFeedUSDT;
    AggregatorV3Interface internal priceFeedMATIC;
   
    constructor(address _USDCAddress, 
                address _USDTAddress,
                address _ERC20Address, 
                uint256 _ERC20ToUSDCRate, 
                uint256 _minimumPurchaseAmount, 
                address _priceFeedUSDC, 
                address _priceFeedUSDT,
                address _priceFeedMATIC) {
        owner = msg.sender;
        
        USDCAddress = _USDCAddress;
        USDTAddress = _USDTAddress;
        ERC20ToUSDCRate = _ERC20ToUSDCRate;
        ERC20Address = _ERC20Address;
        minimumPurchaseAmount = _minimumPurchaseAmount;

        priceFeedUSDC = AggregatorV3Interface(_priceFeedUSDC);
        priceFeedUSDT = AggregatorV3Interface(_priceFeedUSDT);
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

    function getLatestUSDTPrice() public view returns (int256) {
    (
        ,
        int price,
        ,
        ,
        
    ) = priceFeedUSDT.latestRoundData();
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

    function convertToStable(uint256 _TokenAmount) public view returns (uint256) {
        return _TokenAmount.mul(ERC20ToUSDCRate) / 10**14; 
    }

    function convertFromStable(uint256 USDC) public view returns (uint256) {
        return (USDC * 100 / ERC20ToUSDCRate) * 10**12; 
    }

    function getVendingMATICBalance() public view returns(uint256) {
        return address(this).balance;
    }

    modifier checkPurchaseAmount(uint256 _TokenAmount){
        require(_TokenAmount >= minimumPurchaseAmount, "Minimum purchase amount is greater than input amount");
        _;
    }

    modifier sufficientTokenFunds(address fundsOwner, uint256 _TokenAmount){
        IERC20 TOKEN = IERC20(ERC20Address);
        require(TOKEN.balanceOf(fundsOwner) >= _TokenAmount, "Insufficient funds in ERC20");
        _;
    }

    function purchaseForStable(uint256 _TokenAmount, address stableAddress) public payable checkPurchaseAmount(_TokenAmount) sufficientTokenFunds(address(this), _TokenAmount) returns (uint256 spentAmount) {
        uint256 stableAmount = convertToStable(_TokenAmount);
        emit Convertation(_TokenAmount, stableAmount);

        IERC20 STABLE = IERC20(stableAddress);
        IERC20 TOKEN = IERC20(ERC20Address);

        require(STABLE.balanceOf(msg.sender) >= stableAmount, "Insufficient funds in USDT/USDC");
        require(STABLE.allowance(msg.sender, address(this)) >= stableAmount, "Insufficient allowance in USDT/USDC");

        STABLE.safeTransferFrom(msg.sender, address(this), stableAmount);
        emit Transfer(msg.sender, address(this), stableAmount);

        TOKEN.safeTransfer(msg.sender, _TokenAmount);
        emit Transfer(address(this), msg.sender, _TokenAmount);

        return stableAmount;
    }

    function purchaseForUSDC(uint256 _TokenAmount) public payable returns (uint256 spentAmount) {
        return purchaseForStable(_TokenAmount, USDCAddress);
    }

    function purchaseForUSDT(uint256 _TokenAmount) public payable returns (uint256 spentAmount) {
       return purchaseForStable(_TokenAmount, USDTAddress);
    }

    function purchaseForMATIC() public payable returns (uint256 boughtAmount) {
        uint256 _USDCAmount = uint256(uint256(getLatestMATICPrice() / getLatestUSDCPrice()) * msg.value) / 10**12;
        uint256 _TokenAmount = convertFromStable(_USDCAmount);

        require(_TokenAmount >= minimumPurchaseAmount, "Minimum purchase amount is greater than input amount");
        emit Convertation(_TokenAmount, _USDCAmount);
        
        IERC20 TOKEN = IERC20(ERC20Address);

        require(TOKEN.balanceOf(address(this)) >= _TokenAmount, "Insufficient funds in the Vending contract");

        TOKEN.safeTransfer(msg.sender, _TokenAmount);
        emit Transfer(address(this), msg.sender, _TokenAmount);

        return _TokenAmount;
    }

    function withdrawStable(uint256 _TokenAmount, address stableAddress) public payable returns (uint256 withdrawnAmount) {
        uint256 stableAmount = convertToStable(_TokenAmount);
        emit Convertation(_TokenAmount, stableAmount);
        
        IERC20 STABLE = IERC20(stableAddress);
        IERC20 TOKEN = IERC20(ERC20Address);

        require(STABLE.balanceOf(address(this)) >= stableAmount, "Insufficient funds in the Vending contract");
        require(TOKEN.allowance(msg.sender, address(this)) >= _TokenAmount, "Insufficient allowance in ERC20");

        TOKEN.safeTransferFrom(msg.sender, address(this), _TokenAmount);
        emit Transfer(msg.sender, address(this), _TokenAmount);
       
        STABLE.safeTransfer(msg.sender, stableAmount );
        emit Transfer(address(this), msg.sender, stableAmount);

        return stableAmount;
    }

    function withdrawUSDC(uint256 _TokenAmount) public payable nonReentrant sufficientTokenFunds(msg.sender, _TokenAmount) returns (uint256 withdrawnAmount) {
       return withdrawStable(_TokenAmount, USDCAddress);
    }

    function withdrawUSDT(uint256 _TokenAmount) public payable nonReentrant sufficientTokenFunds(msg.sender, _TokenAmount) returns (uint256 withdrawnAmount) {
        return withdrawStable(_TokenAmount, USDTAddress);
    }

    function withdrawMatic(uint256 _TokenAmount) public payable nonReentrant sufficientTokenFunds(msg.sender, _TokenAmount) returns (uint256 withdrawnAmount) {
        
        uint256 _MATICAmount =  (convertToStable(_TokenAmount) * 10**20) / uint256(getLatestMATICPrice()) ;
        emit Convertation(_TokenAmount, _MATICAmount);

        IERC20 TOKEN = IERC20(ERC20Address);

        require(TOKEN.allowance(msg.sender, address(this)) >= _TokenAmount, "Insufficient funds in ERC20");
        require(getVendingMATICBalance() >= _MATICAmount, "Insufficient funds in MATIC");

        TOKEN.safeTransferFrom(msg.sender, address(this), _TokenAmount);
        emit Transfer(msg.sender, address(this), _TokenAmount);

        payable(msg.sender).transfer(_MATICAmount);
        emit Transfer(address(this), msg.sender, _MATICAmount);

        return _MATICAmount;
    }

}
