pragma solidity 0.5.16;
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract Chequing is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    event Mint(address indexed owner, uint256 indexed chequeId);
    event burn(address indexed owner, uint256 indexed chequeId);

    struct Cheque {
        address accountOwner;
        address receiver;
        uint256 id;
        uint256 amount;
        uint256 issueDate;
        uint256 usableFromDate;
        uint256 expiraryDate;
    }

    uint256 private _generalChequeIdNonce = 1;

    mapping (address => uint256) public _chequesOwned;
    mapping (uint256 => address) private _chequesToAddress;
    mapping (uint256 => uint256) private _chequeIdToIndex;
    mapping (uint256 => address) private _chequeApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    Cheque[] _cheques;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _chequesOwned[owner];
    }

    function ownerOf(uint256 _chequeId) public view returns (address) {
        address owner = _chequesToAddress[_chequeId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 chequeId) public {
        address owner = ownerOf(chequeId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _chequeApprovals[chequeId] = to;
        emit Approval(owner, to, chequeId);
    }

    function getApproved(uint256 chequeId) public view returns (address) {
        require(_exists(chequeId), "ERC721: approved query for nonexistent token");

        return _chequeApprovals[chequeId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 chequeId) internal view returns (bool) {
        require(_exists(chequeId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(chequeId);
        return (spender == owner || getApproved(chequeId) == spender || isApprovedForAll(owner, spender));
    }

    function safeTransferFrom(address from, address to, uint256 chequeId) public {
        safeTransferFrom(from, to, chequeId, "");
    }


    function safeTransferFrom(address from, address to, uint256 chequeId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, chequeId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, chequeId, _data);
    }

    function _safeTransferFrom(address from, address to, uint256 chequeId, bytes memory _data) internal {
        _transferFrom(from, to, chequeId);
        require(_checkOnERC721Received(from, to, chequeId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 chequeId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, chequeId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, chequeId);
    }

    function _transferFrom(address from, address to, uint256 chequeId) internal {
        require(ownerOf(chequeId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(chequeId);

        _chequesOwned[from].add(1);
        _chequesOwned[to].sub(1);

        _chequesToAddress[chequeId] = to;

        emit Transfer(from, to, chequeId);
    }

    function _getChequeInformation(uint256 chequeId) public view returns(address, address, uint256, uint256, uint256, uint256, uint256) {
        uint256 chequeIndex = _getChequeIndex(chequeId);
        Cheque memory cheque = _cheques[chequeIndex];
        return (cheque.accountOwner, cheque.receiver, cheque.id, cheque.amount, cheque.issueDate, cheque.usableFromDate, cheque.expiraryDate);
    }

    function _getChequeIndex(uint256 chequeId) internal view returns (uint256) {
        return _chequeIdToIndex[chequeId];
    }

    function _signReceiver(address receiver, uint256 chequeId) public {
        require(receiver != address(0), "Cannot sign a cheque with address 0x0");

        uint256 chequeIndex = _getChequeIndex(chequeId);
        require(_cheques[chequeIndex].receiver == address(0), "A signed cheque cannot be re-signed");
        _cheques[chequeIndex].receiver = receiver;
    }

    function _signAmount(uint256 amount, uint256 chequeId) public {
        require(amount != 0, "Cannot sign a cheque with amount 0");

        uint256 chequeIndex = _getChequeIndex(chequeId);
        require(_cheques[chequeIndex].amount == 0, "A signed cheque cannot be re-signed");
        _cheques[chequeIndex].amount = amount;
    }

    function _signAmountAndReceiver(uint256 amount, address receiver, uint256 chequeId) public {
        require(amount != 0, "Cannot sign a cheque with amount 0");
        require(receiver != address(0), "Cannot sign a cheque with address 0x0");
        require(_isApprovedOrOwner(msg.sender, chequeId), 'Cannot sign a cheque that you do not own or approve of');
        uint256 chequeIndex = _getChequeIndex(chequeId);
        require(_cheques[chequeIndex].amount == 0, "A signed cheque cannot be re-signed");
        require(_cheques[chequeIndex].receiver == address(0), "A signed cheque cannot be re-signed");
        _cheques[chequeIndex].receiver = receiver;
        _cheques[chequeIndex].amount = amount;
    }

    function _safeMint(address receiver, uint256 amount, uint256 usableFromDate, uint256 expiraryDate, bytes memory _data) internal {
        uint256 chequeId = _mint(receiver, amount, usableFromDate, expiraryDate);
        require(_checkOnERC721Received(address(0), msg.sender, chequeId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address receiver, uint256 amount, uint256 usableFromDate, uint256 expiraryDate) internal returns (uint256) {
        uint256 issueDate = block.timestamp;
        require(msg.sender != address(0), "ERC721: mint to the zero address");
        require(issueDate > expiraryDate || expiraryDate == 0, "Cannot create an expired cheque. To create a cheque that doesn't expire, use 0 as [uint256 expiraryDate]");
        _generalChequeIdNonce = _generalChequeIdNonce.add(1);
        Cheque memory newCheque = Cheque(msg.sender, receiver, _generalChequeIdNonce, amount, issueDate, usableFromDate, expiraryDate);
        _cheques.push(newCheque);
        _chequesToAddress[_generalChequeIdNonce] = msg.sender;
        emit Mint(msg.sender, _generalChequeIdNonce);

        return _generalChequeIdNonce;
    }

    function _burn(uint256 chequeId) internal returns (bool) {
        require(_isApprovedOrOwner(msg.sender, chequeId), "ERC721: burn of token that is not own");

        _clearApproval(chequeId);

        _chequesOwned[ownerOf(chequeId)].sub(1);
        _chequesToAddress[chequeId] = address(0);

        emit burn(msg.sender, chequeId);
        return true;
    }

    function _exists(uint256 chequeId) internal view returns (bool) {
        address owner = _chequesToAddress[chequeId];
        return owner != address(0);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_chequeApprovals[tokenId] != address(0)) {
            _chequeApprovals[tokenId] = address(0);
        }
    }

}