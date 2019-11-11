pragma solidity ^0.5.0;

import "./IERC1155e.sol";
import "./IReceiver.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Metadata.sol";


contract Credit is ICredit, Metadata {

    using SafeMath for uint256;
    using Address for address;

    /**
        Multiple transfer with [multi-sender] [multi-receiver] and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement IReceiver.
        MUST be revert if number of `_froms` `_tos` `_ids` and `_values` does not eqaul.
        MUST emit FullBatchTransfer event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _ids      List of ID of the credit types
        @param _values   List of Transfer amounts
    */
    function safeFullBatchTransfer(address[] calldata _froms, address[] calldata _tos, uint256[] calldata _ids,
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
                nfOwners[id] = to;
            } else {
                balances[id][from] = balances[id][from].sub(value);
                balances[id][to]   = value.add(balances[id][to]);
            }
            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, _data);
            }
        }

        emit FullBatchTransfer(msg.sender, _froms, _tos, _ids, _values);
    }

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
    */
    function burnNonFungible(uint256 _id) external {
        require(isNonFungible(_id), "Credit: asset being burned is not a non-fungible asset");
        require(ownerOf(_id) == msg.sender, "Credit: not authorized to burn the credit");
        nfOwners[_id] = address(0);

        emit Transfer(msg.sender, msg.sender, address(0), _id, 1);
    }

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
        @param _quantities Burn Credit quantities
    */
    function burnFungible(uint256 _id, uint256 _quantities) external {
        require(isFungible(_id));
        balances[_id][msg.sender].sub(_value);
        balances[_id].sub(_value);

        emit Transfer(msg.sender, msg.sender, address(0), _id, _value);
    }

    /**
        give `_id` creator authorized to `_minter`.
        @param _type  Credit type
        @param _minter New minter, in case of address 0 the authorized will be locked forever
    */
    function setMinter(uint256 _type, address _minter) external{
        if (isNonFungible(_type)) {
            _type = _type | TYPE_NF_BIT;
        }
        require(creators[_type] == msg.sender, "Credit: sender is not allowed to set minter");
        require(creators[_type] != _minter, "Credit: cannot set current minter as a new minter");
        creators[_type] = _minter;

        emit SetMinter( _type, _minter);
    }

    /**
        @notice Get the total supply of a Credit.
        @param _id     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _id) view external returns(uint256) {
        if (isNonFungible(_id)) {
            uint256 type = getNonFungibleBaseType(id);
            return maxIndex[type] + 1;
        } else {
            return balances[_id][0];
        }
    }
}
