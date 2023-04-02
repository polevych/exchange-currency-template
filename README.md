# Vending Machine Smart Contract

This is a smart contract for a Vending Machine where users can purchase a certain ERC-20 token using USDC, USDT or MATIC (native token of Polygon Network). The contract also supports withdrawal of the ERC-20 tokens in exchange for USDC, USDT or MATIC.

## Prerequisites

This contract uses the following dependencies from OpenZeppelin and Chainlink:

```typescript
"@openzeppelin/contracts/token/ERC20/IERC20.sol";
"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
"@openzeppelin/contracts/security/ReentrancyGuard.sol";
"@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
```

## Contract details:

- **owner**: the address of the contract owner.

- **USDCAddress**: the address of the USDC token.

- **USDTAddress**: the address of the USDC token.

- **ERC20Address**: the address of the ERC-20 token to be purchased.

- **ERC20ToUSDCRate**: the conversion rate from the ERC-20 token to USDC in %.

- **minimumPurchaseAmount**: the minimum amount of ERC-20 token that can be purchased at a time.

- **priceFeedUSDC**: Chainlink Price Feed Contract address for the USDC/USD pair.

- **priceFeedUSDT**: Chainlink Price Feed Contract address for the USDT/USD pair.

- **priceFeedMATIC**: Chainlink Price Feed Contract address for the MATIC/USD pair.

### The contract has the following functions:

- **getLatestUSDCPrice():** returns the latest price of USDC in USD ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)).
- **getLatestMATICPrice():** returns the latest price of MATIC in USD ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)).
- **convertToStable(uint256 \_TokenAmount):** converts the given \_TokenAmount of ERC-20 token to stable coin(USDT/USDC).
- **convertFromStable(uint256 USDC):** converts the given stable coin(USDT/USDC) amount to ERC-20 token.
- **getVendingMATICBalance():** returns the balance of MATIC in the contract.
- **checkPurchaseAmount(uint256 \_TokenAmount):** modifier to check if the \_TokenAmount is greater than or equal to the minimumPurchaseAmount.
- **sufficientTokenFunds(address fundsOwner, uint256 \_TokenAmount):** modifier to check if the fundsOwner has sufficient ERC-20 tokens for the \_TokenAmount.
- **purchaseForStable(uint256 \_TokenAmount, address \_stableAddress):** allows the user to purchase ERC-20 token in exchange for stable coin(USDT/USDC).
- **purchaseForUSDC(uint256 \_TokenAmount):** allows the user to purchase ERC-20 token in exchange for USDC using purchaseForStable with USDC address.
- **purchaseForUSDT(uint256 \_TokenAmount):** allows the user to purchase ERC-20 token in exchange for USDT using purchaseForStable with USDT address.
- **purchaseForMATIC():** allows the user to purchase ERC-20 token in exchange for MATIC.
- **withdrawStable(uint256 \_TokenAmount, address \_stableAddress):** allows the user to withdraw ERC-20 tokens in exchange for stable coin(USDT/USDC).
- **withdrawUSDC(uint256 \_TokenAmount):** allows the user to withdraw ERC-20 tokens in exchange for USDC using withdrawStable with USDC address.
- **withdrawUSDT(uint256 \_TokenAmount):** allows the user to withdraw ERC-20 tokens in exchange for USDT using withdrawStable with USDT address.

## Usage

**Install the dependencies:**

```typescript
yarn
```

To use this contract, you need to deploy it on the Polygon Network. You can also use it as a template to create similar contracts on other networks (you need to work with decimals).
You can find sample deploy script `scripts/deploy-vending.ts` and .env.example. The contract constructor takes the following parameters:

- **\_USDCAddress:** the address of the USDC token.
- **\_USDTAddress:** the address of the USDT token.
- **\_ERC20Address:** the address of the ERC-20 token to be purchased.
- **\_ERC20ToUSDCRate:** the conversion rate from the ERC-20 token to USDC.
- **\_minimumPurchaseAmount:** the minimum amount of ERC-20 token that can be purchased at a time.
- **\_priceFeedUSDC:** ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)) Price Feed Contract address for the USDC/USD pair.
- **\_priceFeedUSDT:** ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)) Price Feed Contract address for the USDT/USD pair.
- **\_priceFeedMATIC:** ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)) Price Feed Contract address for the MATIC/USD pair.

## Testing

You can find chai test for all base functions in `tests/vending-machine.test.ts` and run it with following command:

```typescript
npx hardhat test
```
