require("dotenv").config();
import hre from "hardhat";

async function main() {
  const contract = await hre.ethers.getContractFactory("VendingMachine");
  const vendingMachine = await contract.deploy(
    process.env.USDC_ADDRESS,
    process.env.USDT_ADDRESS,
    process.env.ERC20_ADDRESS,
    process.env.ERC20_TO_USDC_RATE,
    process.env.MINIMUM_PURCHASE_AMOUNT,
    process.env.PRICE_FEED_USDC,
    process.env.PRICE_FEED_USDT,
    process.env.PRICE_FEED_MATIC
  );

  console.log(
    `Vending Machine contract deployed to: ${vendingMachine.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
