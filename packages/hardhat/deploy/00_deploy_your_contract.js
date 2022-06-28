// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("MultiSigWallet", {
    from: deployer,
    args: [["0x455f0Ecec99AAc87498978EA62f5333b1F90b2dD", "0x674794163e4FFF1f1bb5e7825bBc9C566c7731f0", "0x97843608a00e2bbc75ab0C1911387E002565DEDE"], 2],
    log: true,
    waitConfirmations: 5,
  });

  const MultiSigWallet = await ethers.getContract("MultiSigWallet", deployer);

  // Verify from the command line by running `yarn verify`
  try {
    if (chainId !== localChainId) {
      await run("verify:verify", {
        address: MultiSigWallet.address,
        contract: "contracts/MultiSigWallet.sol:MultiSigWallet",
        constructorArguments: [],
      });
    }
  } catch (error) {
    console.error(error);
  }
};
module.exports.tags = ["MultiSigWallet"];
