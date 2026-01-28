import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  AssociationSetRegistry__factory,
  InstitutionalPool__factory,
  MockComplianceVerifier__factory,
  MockERC20__factory,
} from "../exports/types";

describe("InstitutionalPool", () => {
  async function deployFixture() {
    const [deployer, other, recipient] = await ethers.getSigners();

    const registry = await new AssociationSetRegistry__factory(deployer).deploy();
    await registry.waitForDeployment();

    const verifier = await new MockComplianceVerifier__factory(deployer).deploy();
    await verifier.waitForDeployment();

    const token = await new MockERC20__factory(deployer).deploy("Mock Token", "MOCK");
    await token.waitForDeployment();

    const policyId = ethers.id("policy-1");
    const pool = await new InstitutionalPool__factory(deployer).deploy(
      await registry.getAddress(),
      await verifier.getAddress(),
      policyId,
    );
    await pool.waitForDeployment();

    return { deployer, other, recipient, registry, verifier, token, pool, policyId };
  }

  it("deposit transfers tokens in and emits Deposit", async () => {
    const { deployer, token, pool } = await loadFixture(deployFixture);

    const amount = 100n;
    await token.mint(deployer.address, amount);
    await token.approve(await pool.getAddress(), amount);

    await expect(pool.deposit(await token.getAddress(), amount))
      .to.emit(pool, "Deposit")
      .withArgs(deployer.address, await token.getAddress(), amount);

    expect(await token.balanceOf(await pool.getAddress())).to.equal(amount);
  });

  it("withdraw fails when setId is unknown", async () => {
    const { deployer, token, pool } = await loadFixture(deployFixture);

    const amount = 50n;
    await token.mint(deployer.address, amount);
    await token.approve(await pool.getAddress(), amount);
    await pool.deposit(await token.getAddress(), amount);

    await expect(
      pool.withdraw(
        await token.getAddress(),
        10n,
        deployer.address,
        999,
        "0x",
        "0x",
        ethers.id("withdraw-1"),
      ),
    )
      .to.be.revertedWithCustomError(pool, "UnknownSet")
      .withArgs(999);
  });

  it("withdraw fails when verifier rejects", async () => {
    const { deployer, registry, verifier, token, pool } = await loadFixture(deployFixture);

    const setId = 1;
    const root = ethers.id("set-root");
    await registry.createSet(setId, root);

    await verifier.setAccept(false);

    const amount = 50n;
    await token.mint(deployer.address, amount);
    await token.approve(await pool.getAddress(), amount);
    await pool.deposit(await token.getAddress(), amount);

    await expect(
      pool.withdraw(
        await token.getAddress(),
        10n,
        deployer.address,
        setId,
        "0x",
        "0x",
        ethers.id("withdraw-2"),
      ),
    ).to.be.revertedWithCustomError(pool, "VerificationFailed");
  });

  it("withdraw succeeds when setId known and verifier accepts", async () => {
    const { deployer, recipient, registry, verifier, token, pool, policyId } =
      await loadFixture(deployFixture);

    const setId = 42;
    const root = ethers.id("set-root-42");
    await registry.createSet(setId, root);
    await verifier.setAccept(true);

    const depositAmount = 200n;
    const withdrawAmount = 80n;
    await token.mint(deployer.address, depositAmount);
    await token.approve(await pool.getAddress(), depositAmount);
    await pool.deposit(await token.getAddress(), depositAmount);

    const withdrawalId = ethers.id("withdraw-3");
    await expect(
      pool.withdraw(
        await token.getAddress(),
        withdrawAmount,
        recipient.address,
        setId,
        "0x",
        "0x",
        withdrawalId,
      ),
    )
      .to.emit(pool, "Withdrawal")
      .withArgs(
        deployer.address,
        recipient.address,
        await token.getAddress(),
        withdrawAmount,
        setId,
        root,
        policyId,
        withdrawalId,
      );

    expect(await token.balanceOf(recipient.address)).to.equal(withdrawAmount);
    expect(await token.balanceOf(await pool.getAddress())).to.equal(depositAmount - withdrawAmount);
  });

  it("withdraw fails on replay with same withdrawalId", async () => {
    const { deployer, registry, verifier, token, pool } = await loadFixture(deployFixture);

    const setId = 7;
    const root = ethers.id("set-root-7");
    await registry.createSet(setId, root);
    await verifier.setAccept(true);

    const amount = 100n;
    await token.mint(deployer.address, amount);
    await token.approve(await pool.getAddress(), amount);
    await pool.deposit(await token.getAddress(), amount);

    const withdrawalId = ethers.id("withdraw-4");
    await pool.withdraw(
      await token.getAddress(),
      25n,
      deployer.address,
      setId,
      "0x",
      "0x",
      withdrawalId,
    );

    await expect(
      pool.withdraw(
        await token.getAddress(),
        25n,
        deployer.address,
        setId,
        "0x",
        "0x",
        withdrawalId,
      ),
    )
      .to.be.revertedWithCustomError(pool, "WithdrawalAlreadySpent")
      .withArgs(withdrawalId);
  });

  it("access control and pause behavior", async () => {
    const { other, registry, verifier, token, pool } = await loadFixture(deployFixture);

    await expect(pool.connect(other).setVerifier(await verifier.getAddress())).to.be.reverted;
    await expect(pool.connect(other).setRegistry(await registry.getAddress())).to.be.reverted;
    await expect(pool.connect(other).setPolicyId(ethers.id("policy-2"))).to.be.reverted;

    await expect(pool.connect(other).pause()).to.be.reverted;
    await pool.pause();

    await expect(pool.deposit(await token.getAddress(), 1n)).to.be.reverted;
    await expect(
      pool.withdraw(
        await token.getAddress(),
        1n,
        other.address,
        1,
        "0x",
        "0x",
        ethers.id("withdraw-paused"),
      ),
    ).to.be.reverted;

    await expect(pool.connect(other).unpause()).to.be.reverted;
    await pool.unpause();
  });

  it("registry events and constraints", async () => {
    const { registry, deployer } = await loadFixture(deployFixture);

    const setId = 5;
    const rootA = ethers.id("root-a");
    const rootB = ethers.id("root-b");

    await expect(registry.createSet(setId, rootA))
      .to.emit(registry, "SetCreated")
      .withArgs(setId, rootA, deployer.address);

    await expect(registry.createSet(setId, rootA))
      .to.be.revertedWithCustomError(registry, "SetAlreadyExists")
      .withArgs(setId);

    await expect(registry.updateSet(setId, rootB))
      .to.emit(registry, "SetUpdated")
      .withArgs(setId, rootA, rootB, deployer.address);

    await expect(registry.updateSet(999, rootB))
      .to.be.revertedWithCustomError(registry, "SetUnknown")
      .withArgs(999);
  });
});
