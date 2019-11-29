pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155e.sol";
import "./ERC1155MixedFungibleMintable.sol";

contract ERC1155e is IERC1155e, ERC1155MixedFungibleMintable {

    using SafeMath for uint256;
    using Address for address;

    /**
        Multiple transfer with [multi-sender] [multi-receiver] and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement ERC1155TokenReceiver.
        MUST be revert if number of `_froms` `_tos` `_ids` and `_values` does not eqaul.
        MUST emit TransferFullBatch event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _ids      List of ID of the credit types
        @param _values   List of Transfer amounts
        @param _data     Data sending to event logs
    */
    function safeFullBatchTransferFrom(address[] calldata _froms, address[] calldata _tos, uint256[] calldata _ids,
                                   uint256[] calldata _values, bytes calldata _data) external {
        require(_froms.length == _tos.length && _froms.length == _ids.length && _froms.length == _values.length, "Credit: Array length must match");

        for( uint256 i = 0; i < _froms.length; ++i) {
            // Cache value to local variable to reduce read costs.
            address from = _froms[i];
            address to = _tos[i];
            uint256 id = _ids[i];
            uint256 value = _values[i];

            require(to != address(0x0), "Credit: cannot send to zero address");
            require(from == msg.sender || operatorApproval[from][msg.sender] == true, "Credit: Need operator approval for 3rd party transfers.");
            if (isNonFungible(id)) {
                require(nfOwners[id] == from);
                uint256 baseType = getNonFungibleBaseType(id);
                nfOwners[id] = to;
                balances[baseType][from] = balances[baseType][from].sub(1);
                balances[baseType][to]   = balances[baseType][to].add(1);
            } else {
                balances[id][from] = balances[id][from].sub(value);
                balances[id][to]   = value.add(balances[id][to]);
            }
            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, _data);
            }
        }

        emit TransferFullBatch(msg.sender, _froms, _tos, _ids, _values, _data);
    }

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
    */
    function burnNonFungible(uint256 _id) external {
        
        require(isNonFungible(_id), "Credit: asset being burned is not a non-fungible asset");
        require(ownerOf(_id) == msg.sender, "Credit: not authorized to burn the credit");

        uint256 _type = this.getNonFungibleBaseType(_id);
        nfOwners[_id] = address(0);
        balances[_type][msg.sender] = balances[_type][msg.sender].sub(1);
        totalSupplies[_type] = totalSupplies[_type].sub(1);
        totalSupplies[_id] = totalSupplies[_id].sub(1);

        emit TransferSingle(msg.sender, msg.sender, address(0), _id, 1);
    }

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
        @param _quantities Burn Credit quantities
    */
    function burnFungible(uint256 _id, uint256 _quantities) external {

        require(isFungible(_id));
        
        balances[_id][msg.sender] = balances[_id][msg.sender].sub(_quantities);
        totalSupplies[_id] = totalSupplies[_id].sub(_quantities);

        emit TransferSingle(msg.sender, msg.sender, address(0), _id, _quantities);
    }

    /**
        give `_type` creator authorized to `_minter`.
        @param _type  Credit _id (when credit is fungible) or _type (when credit is non-fungible)
        @param _minter New minter, in case of address 0 the authorized will be locked forever
    */
    function setMinter(uint256 _type, address _minter) external minterOnly(_type) {
        
        require(minters[_type] != _minter, "Credit: cannot set current minter as a new minter");
        minters[_type] = _minter;

        emit SetMinter( _type, _minter);
    }

    /**
        @notice Get the total supply of a Credit.
        @param _id     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _id) view external returns(uint256) {
            return totalSupplies[_id];
    }
}
