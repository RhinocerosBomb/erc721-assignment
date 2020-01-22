pragma solidity 0.5.16;
import "./SafeMath.sol";

contract Bank {
    using SafeMath for uint256;
    event Deposit(address indexed accountOwner, uint256 indexed ammount);
    event Withdraw(address indexed accountOwner, uint256 indexed ammount);

    mapping (address => uint256) public _ethBalance;

    function _deposit() public payable {
        _ethBalance[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function _withdraw(uint256 amount) public {
        _ethBalance[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}