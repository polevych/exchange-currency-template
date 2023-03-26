import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, Event, Signer } from "ethers";
import { Token, VendingMachine } from "../typechain-types";

enum EVENT_TYPES {
  TRANSFER = "Transfer",
}

describe("VendingMachine", function () {
  let vendingMachine: Contract,
    USDC: Contract,
    token: Contract,
    TOKEN_TO_USDC_RATE: number,
    MINIMUM_PURCHASE_AMOUNT: number,
    owner: Signer,
    user1: Signer,
    user2: Signer;

  beforeEach(async () => {
    [owner, user1, user2] = await ethers.getSigners();

    const tokenFactory = await ethers.getContractFactory("Token");
    token = (await tokenFactory
      .connect(owner)
      .deploy("ERC20", "ERC20")) as Token;
    USDC = (await tokenFactory.connect(owner).deploy("USDC", "USDC")) as Token;

    await USDC.connect(owner).mint(await user1.getAddress(), 15 * 10 ** 6);
    await USDC.connect(owner).mint(await user2.getAddress(), 15 * 10 ** 6);

    const vendingMacineFactory = await ethers.getContractFactory(
      "VendingMachine"
    );

    TOKEN_TO_USDC_RATE = 10;
    MINIMUM_PURCHASE_AMOUNT = 10;

    vendingMachine = (await vendingMacineFactory.connect(owner).deploy(
      USDC.address,
      TOKEN_TO_USDC_RATE,
      token.address,
      MINIMUM_PURCHASE_AMOUNT,
      "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0", // Polygon Mumbai (USDC / USD) | decimals - 8
      "0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada" // Polygon Mumbai (MATIC / USD) | decimals - 8
    )) as VendingMachine;

    await USDC.connect(owner).mint(vendingMachine.address, 10 * 10 ** 6);

    await USDC.connect(user1).increaseAllowance(
      vendingMachine.address,
      5 * 10 ** 6
    );

    await USDC.connect(user2).increaseAllowance(
      vendingMachine.address,
      1 * 10 ** 6
    );

    await token
      .connect(owner)
      .mint(vendingMachine.address, ethers.utils.parseEther("50000"));
    await token
      .connect(owner)
      .mint(await user2.getAddress(), ethers.utils.parseEther("15"));

    await token
      .connect(user2)
      .increaseAllowance(vendingMachine.address, ethers.utils.parseEther("10"));
  });

  it("should convert tokens to USDC", async function () {
    expect(
      await vendingMachine.convertToUSDC(ethers.utils.parseEther("2"))
    ).to.be.equal(
      (Number(ethers.utils.parseEther("2")) * TOKEN_TO_USDC_RATE) / 10 ** 14
    );
  });

  it("should convert tokens from USDC", async function () {
    expect(await vendingMachine.convertFromUSDC(10000000)).to.be.equal(
      BigInt((10000000 * 100) / TOKEN_TO_USDC_RATE) * BigInt(10 ** 12)
    );
  });

  describe("purchaseForUSDC", function () {
    it("should fail if the purchase amount is less than the minimum purchase amount", async function () {
      const purchaseAmount = MINIMUM_PURCHASE_AMOUNT - 1;
      await expect(
        vendingMachine.purchaseForUSDC(purchaseAmount)
      ).to.be.revertedWith(
        "Minimum purchase amount is greater than input amount"
      );
    });

    it("should fail if the Veding machine does not have enough TOKEN to cover the purchase", async function () {
      await expect(
        vendingMachine
          .connect(user1)
          .purchaseForUSDC(ethers.utils.parseEther("60000"))
      ).to.be.revertedWith("Insufficient funds in ERC20");
    });

    it("should fail if caller does not have enough USDC to cover the purchase", async function () {
      await expect(
        vendingMachine
          .connect(user1)
          .purchaseForUSDC(ethers.utils.parseEther("15000"))
      ).to.be.revertedWith("Insufficient funds in USDC");
    });

    it("should fail if caller does not give enough allowance inside USDC for the Vending contract", async function () {
      await expect(
        vendingMachine
          .connect(user2)
          .purchaseForUSDC(ethers.utils.parseEther("130"))
      ).to.be.revertedWith("Insufficient allowance in USDC");
    });

    it("should purchase tokens for USDC and transfer them to the caller", async function () {
      const tokenAmount = 15;
      const userERC20BalanceBefore = await token.balanceOf(
        await user1.getAddress()
      );
      const vendingUSDCBalanceBefore = await USDC.balanceOf(
        vendingMachine.address
      );

      const tx = await vendingMachine
        .connect(user1)
        .purchaseForUSDC(tokenAmount);

      const events = (await tx.wait()).events;
      const transferEvents = events
        .filter(
          (event: Event) =>
            event.event === EVENT_TYPES.TRANSFER && event.args !== undefined
        )
        .map((event: Event) => event.args);

      expect(transferEvents && transferEvents[0] && transferEvents[1]).to.not.be
        .undefined;

      expect(transferEvents[0].from).to.be.equal(await user1.getAddress());
      expect(transferEvents[0].amount).to.be.equal(
        await vendingMachine.convertToUSDC(tokenAmount)
      );
      expect(transferEvents[0].to).to.be.equal(vendingMachine.address);

      expect(transferEvents[1].from).to.be.equal(vendingMachine.address);
      expect(transferEvents[1].amount).to.be.equal(tokenAmount);
      expect(transferEvents[1].to).to.be.equal(await user1.getAddress());

      expect(await token.balanceOf(await user1.getAddress())).to.be.equal(
        userERC20BalanceBefore.add(tokenAmount)
      );

      expect(await USDC.balanceOf(vendingMachine.address)).to.be.equal(
        vendingUSDCBalanceBefore.add(
          await vendingMachine.convertToUSDC(tokenAmount)
        )
      );
    });
  });

  describe("withdraw", function () {
    it("should fail if caller does not have enough ERC20 to cover the purchase", async function () {
      await expect(
        vendingMachine.connect(user1).withdraw(ethers.utils.parseEther("18000"))
      ).to.be.revertedWith("Insufficient funds in ERC20");
    });

    it("should fail if caller does not give enough allowance inside ERC20 for the Vending contract", async function () {
      await expect(
        vendingMachine.connect(user2).withdraw(ethers.utils.parseEther("12"))
      ).to.be.revertedWith("Insufficient allowance in ERC20");
    });

    it("should withdraw funds from ERC20 to USDC", async function () {
      const tokenAmount = 10;
      await vendingMachine.connect(user2).purchaseForUSDC(tokenAmount);

      const userUSDCBalanceBefore = await USDC.balanceOf(
        await user2.getAddress()
      );
      const vendingERC20BalanceBefore = await token.balanceOf(
        vendingMachine.address
      );

      await vendingMachine.connect(user2).withdraw(tokenAmount);

      expect(await USDC.balanceOf(await user2.getAddress())).to.be.equal(
        userUSDCBalanceBefore.add(
          await vendingMachine.convertToUSDC(tokenAmount)
        )
      );

      expect(await token.balanceOf(vendingMachine.address)).to.be.equal(
        vendingERC20BalanceBefore.add(tokenAmount)
      );
    });
  });
});
