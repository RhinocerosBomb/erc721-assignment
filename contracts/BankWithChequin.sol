pragma solidity 0.5.16;
import "./Bank.sol";
import "./Chequing.sol";

contract BankWithChequing is Bank, Chequing {
    function _printCheque(address receiver, uint256 amount, uint256 usableFromDate, uint256 expiraryDate, bytes memory _data)
    public returns (bool) {
        _safeMint(receiver, amount, usableFromDate, expiraryDate, _data);
        return true;
    }

    function _printBlankCheque(uint256 usableFromDate, uint256 expiraryDate, bytes memory _data) public returns (bool){
        return _printCheque(address(0), 0, usableFromDate, expiraryDate, _data);
    }

    function _cashCheque(uint256 chequeId) public {
        require(chequeId != 0, "[uint256 chequeId] cannot be zero");
        uint256 chequeIndex = _getChequeIndex(chequeId);
        require(chequeIndex > 0, "Cheque with this id does not exist ");
        uint256 timestamp = block.timestamp;
        Cheque memory cheque = _cheques[chequeIndex];
        require(cheque.usableFromDate > timestamp, "Cheque is not valid to use at this time");
        require(cheque.expiraryDate == 0 || cheque.expiraryDate > timestamp, "Cheque is expired");

        ethBalance[cheque.accountOwner] = ethBalance[cheque.accountOwner].sub(cheque.amount);
            ethBalance[cheque.receiver] = ethBalance[cheque.receiver].add(cheque.amount);
        _burn(cheque.id);
    }
}