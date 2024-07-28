import { ethers } from "hardhat";
import { expect } from "chai";
import { WeightedIndex, ERC20Mock, MockPriceFeedOracle } from "../typechain-types";

describe("WeightedIndex", function () {
  let index: WeightedIndex;
  let token1: ERC20Mock;
  let token2: ERC20Mock;
  let oracle: MockPriceFeedOracle;
  let owner: any;

  const initialSupply = ethers.parseUnits("1000", 18);
  const token1Price = ethers.parseUnits("2", 18); // $2 per token
  const token2Price = ethers.parseUnits("1", 18); // $1 per token

  before(async function () {
    [owner] = await ethers.getSigners();

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

    token1 = await ERC20Mock.deploy("Token1", "TK1", initialSupply);
    await token1.waitForDeployment();

    token2 = await ERC20Mock.deploy("Token2", "TK2", initialSupply);
    await token2.waitForDeployment();

    const MockPriceFeedOracle = await ethers.getContractFactory("MockPriceFeedOracle");
    oracle = (await MockPriceFeedOracle.deploy()) as MockPriceFeedOracle;
    await oracle.waitForDeployment();

    await oracle.setPrice(token1.target, token1Price);
    await oracle.setPrice(token2.target, token2Price);

    const WeightedIndex = await ethers.getContractFactory("WeightedIndex");
    index = await WeightedIndex.deploy(token1.target, token2.target, oracle.target);

    await index.waitForDeployment();

    await token1.transfer(index.target, initialSupply / 2n); // 500 tokens
    await token2.transfer(index.target, initialSupply / 2n); // 500 tokens

    await index.updatePrices();
    await index.rebalance();
  });

  it("should initialize the contract correctly", async function () {
    expect(await index.token1()).to.equal(token1.target);
    expect(await index.token2()).to.equal(token2.target);
  });

  it("should update prices correctly", async function () {
    const newToken1Price = 3n * 10n ** 18n;
    const newToken2Price = 2n * 10n ** 18n;

    await oracle.setPrice(token1.target, newToken1Price);
    await oracle.setPrice(token2.target, newToken2Price);

    expect(await oracle.getPrice(token1.target)).to.equal(newToken1Price);
    expect(await oracle.getPrice(token2.target)).to.equal(newToken2Price);

    await index.updatePrices();

    expect(await index.token1Price()).to.equal(newToken1Price);
    expect(await index.token2Price()).to.equal(newToken2Price);
  });

  it("should calculate index value correctly", async function () {
    await oracle.setPrice(token1.target, token1Price);
    await oracle.setPrice(token2.target, token2Price);
    await index.updatePrices();
    const weights = await index.getWeights();

    const indexValue = await index.getIndexValue();
    const expectedValue =
      (token1Price * (initialSupply / 2n) * weights[0]) / 10000n +
      (token2Price * (initialSupply / 2n) * weights[1]) / 10000n;

    expect(indexValue).to.equal(expectedValue);
  });

  it("should rebalance weights correctly", async function () {
    const indexValStart = await index.getIndexValue();
    const w1Start = await index.weight1();
    const w2Start = await index.weight2();

    await oracle.setPrice(token1.target, ethers.parseUnits("2.1", 18));
    await oracle.setPrice(token2.target, ethers.parseUnits("1", 18));

    await index.updatePrices();
    await index.rebalance();

    const indexValEnd = await index.getIndexValue();
    const w1End = await index.weight1();
    const w2End = await index.weight2();

    expect(indexValEnd).to.be.above(indexValStart);
    expect(w1End).to.be.above(w1Start);
    expect(w2End).to.be.below(w1End);

    expect(w1Start + w2Start).to.equal(10000 - 1); // With rounding will never amount to 10000 exactly
    expect(w1End + w2End).to.equal(10000 - 1);
  });

  it("should mint and burn index tokens correctly", async function () {
    const mintAmount = ethers.parseUnits("100", 18);
    await index.mint(mintAmount);
    expect(await index.balanceOf(owner.address)).to.equal(mintAmount);
    const burnAmount = ethers.parseUnits("50", 18);
    await index.burn(burnAmount);
    expect(await index.balanceOf(owner.address)).to.equal(mintAmount - burnAmount);
  });
});
