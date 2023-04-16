require("dotenv").config();
import hre from "hardhat";

async function main() {
  const name = process.env.ERC20_NAME;
  const symbol = process.env.ERC20_SYMBOL;

  const contract = await hre.ethers.getContractFactory("Token");
  const token = await contract.deploy(name, symbol);

  console.log(`Token contract deployed to: ${token.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
