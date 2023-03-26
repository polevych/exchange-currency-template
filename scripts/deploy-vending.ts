import hre from "hardhat";

async function main() {
  const VendingMachine = await hre.ethers.getContractFactory("VendingMachine");
  const contract = await VendingMachine.deploy(
    process.env.USDC_ADDRESS,
    process.env.TOKEN_TO_USDC_RATE,
    process.env.TOKEN_ADDRESS,
    process.env.MINIMUM_PURCHASE_AMOUNT,
    process.env.USDC_USD_PRICE_FEED,
    process.env.USDC_USD_PRICE_FEED
  );

  await contract.deployed();

  console.log(`VendingMachine  deployed to ${contract.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
