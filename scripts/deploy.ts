import { ethers } from "hardhat";

async function main() {

  ///DEPLOYING A TOKEN SAMPLE FOR INTERACTION
  const YamToken = await ethers.getContractFactory("YamToken");
  const yam = await YamToken.deploy();

  await yam.deployed();

  console.log("Yamtoken Contract Address is", yam.address);

  ///DEPLOYING LAUNCHPAD CONTRACT
  const LaunchPad = await ethers.getContractFactory("Launchpad");
  const IDOPad = await LaunchPad.deploy();

  await IDOPad.deployed();

  console.log("LaunchPad Contract Address is", IDOPad.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
