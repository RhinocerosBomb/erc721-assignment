pragma solidity 0.5.16;
import "./SafeMath.sol";

contract SimpleBank {
    using SafeMath for uint256;
    mapping (address => uint256) public ethBalance;

    function deposit() public payable {
        ethBalance[msg.sender].add(msg.value);
    }

    function withdraw(uint256 amount) public {
        ethBalance[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }
}