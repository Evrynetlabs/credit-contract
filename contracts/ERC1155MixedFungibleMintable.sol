pragma solidity ^0.5.0;

import "./ERC1155MixedFungible.sol";
import "./IERC1155Metadata.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract ERC1155MixedFungibleMintable is ERC1155MixedFungible, IERC1155Metadata {

    uint256 nonce;
    mapping (uint256 => address) public minters;
    mapping (uint256 => uint256) public maxIndex;
    mapping (uint256 => uint256) public totalSupplies;
    mapping (uint256 => string) public metalinks;

    modifier minterOnly(uint256 _id) {
        require(minters[_id] == msg.sender);
        _;
    }

    // This function only creates the type.
    function create(
        string calldata _metalink,
        bool   _isNF)
    external returns(uint256 _type) {

        // Store the type in the upper 128 bits
        _type = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF)
          _type = _type | TYPE_NF_BIT;

        // This will allow restricted access to minters.
        minters[_type] = msg.sender;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);

        if (bytes(_metalink).length > 0)
            metalinks[_type] = _metalink;
            emit URI(_metalink, _type);
    }

    function mintNonFungible(uint256 _type, address[] calldata _tos) external minterOnly(_type) {

        // No need to check this is a nf type rather than an id since
        // minterOnly() will only let a type pass through.
        require(isNonFungible(_type));

        // Index are 1-based.
        uint256 index = maxIndex[_type] + 1;
        maxIndex[_type] = _tos.length.add(maxIndex[_type]);

        for (uint256 i = 0; i < _tos.length; ++i) {
            address to = _tos[i];
            uint256 id  = _type | index + i;

            nfOwners[id] = to;
            balances[_type][to] = balances[_type][to].add(1);
            totalSupplies[_type] = totalSupplies[_type].add(1);
            totalSupplies[id] = totalSupplies[id].add(1);

            emit TransferSingle(msg.sender, address(0x0), to, id, 1);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, id, 1, '');
            }
        }
    }

    function mintFungible(uint256 _id, address[] calldata _tos, uint256[] calldata _quantities) external minterOnly(_id) {

        require(isFungible(_id));
        require(_tos.length == _quantities.length, "Credit: Array length must match");

        for (uint256 i = 0; i < _tos.length; ++i) {

            address to = _tos[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);
            totalSupplies[_id] = totalSupplies[_id].add(quantity);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    function uri(uint256 _id) external view returns (string memory) {
        return metalinks[_id];
    }
}
