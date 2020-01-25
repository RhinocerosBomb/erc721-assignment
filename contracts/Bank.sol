pragma solidity 0.5.16;
import "./SafeMath.sol";

contract Bank {
    using SafeMath for uint256;
    event Deposit(address indexed accountOwner, uint256 indexed amount);
    event Withdraw(address indexed accountOwner, uint256 indexed amount);

    mapping (address => uint256) public ethBalance;

    function getEthBalance() public view returns (uint256) {
        return getEthBalance(msg.sender);
    }

    function getEthBalance(address owner) public view returns (uint256) {
        return ethBalance[owner];
    }

    function deposit() public payable {
        ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        ethBalance[msg.sender] = ethBalance[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}