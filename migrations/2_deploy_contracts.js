const SafeMath = artifacts.require("SafeMath");
const BankWithChequing = artifacts.require("BankWithChequing.sol");
const Address = artifacts.require("Address.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(Address);
  deployer.link(SafeMath, BankWithChequing);
  deployer.link(Address, BankWithChequing);
  deployer.deploy(BankWithChequing);
};
