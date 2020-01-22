const SafeMath = artifacts.require("SafeMath");
const SimpleBank = artifacts.require("SimpleBank");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, SimpleBank);
  deployer.deploy(SimpleBank);
};
