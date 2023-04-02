# Vending Machine Smart Contract

This is a smart contract for a Vending Machine where users can purchase a certain ERC-20 token using USDC or MATIC (native token of Polygon Network). The contract also supports withdrawal of the ERC-20 tokens in exchange for USDC or MATIC.

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

- **ERC20Address**: the address of the ERC-20 token to be purchased.

- **ERC20ToUSDCRate**: the conversion rate from the ERC-20 token to USDC in %.

- **minimumPurchaseAmount**: the minimum amount of ERC-20 token that can be purchased at a time.

- **priceFeedUSDC**: Chainlink Price Feed Contract address for the USDC/USD pair.

- **priceFeedMATIC**: Chainlink Price Feed Contract address for the MATIC/USD pair.

### The contract has the following functions:

- **getLatestUSDCPrice():** returns the latest price of USDC in USD ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)).
- **getLatestMATICPrice():** returns the latest price of MATIC in USD ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)).
- **convertToUSDC(uint256 \_TokenAmount):** converts the given \_TokenAmount of ERC-20 token to USDC.
- **convertFromUSDC(uint256 USDC):** converts the given USDC amount to ERC-20 token.
- **getVendingMATICBalance():** returns the balance of MATIC in the contract.
- **checkPurchaseAmount(uint256 \_TokenAmount):** modifier to check if the \_TokenAmount is greater than or equal to the minimumPurchaseAmount.
- **sufficientTokenFunds(address fundsOwner, uint256 \_TokenAmount):** modifier to check if the fundsOwner has sufficient ERC-20 tokens for the \_TokenAmount.
- **purchaseForUSDC(uint256 \_TokenAmount):** allows the user to purchase ERC-20 token in exchange for USDC.
- **purchaseForMATIC():** allows the user to purchase ERC-20 token in exchange for MATIC.
- **withdraw(uint256 \_TokenAmount):** allows the user to withdraw ERC-20 tokens in exchange for USDC.

## Usage

**Install the dependencies:**

```typescript
yarn;
```

To use this contract, you need to deploy it on the Polygon Network. You can also use it as a template to create similar contracts on other networks (you need to work with decimals).
You can find sample deploy script `scripts/deploy-vending.ts` and .env.example. The contract constructor takes the following parameters:

- **\_USDCAddress:** the address of the USDC token.
- **\_ERC20ToUSDCRate:** the conversion rate from the ERC-20 token to USDC.
- **\_ERC20Address:** the address of the ERC-20 token to be purchased.
- **\_minimumPurchaseAmount:** the minimum amount of ERC-20 token that can be purchased at a time.
- **\_priceFeedUSDC:** ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)) Price Feed Contract address for the USDC/USD pair.
- **\_priceFeedMATIC:** ([_Chainlink_](https://docs.chain.link/data-feeds/price-feeds/addresses)) Price Feed Contract address for the MATIC/USD pair.

## Testing

You can find chai test for all base functions in `tests/vending-machine.test.ts` and run it with following command:

```typescript
npx hardhat test
```
