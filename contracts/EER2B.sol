pragma solidity ^0.5.0;

import "./EER2A.sol";
import "./IEER2B.sol";

contract EER2B is IEER2B, EER2A {
    // This function only creates the type.
    function create(string calldata _metaLink, bool _isNF)
        external
        returns (uint256 _typeID)
    {
        // Store the type in the upper 128 bits
        _typeID = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF) _typeID = _typeID | TYPE_NF_BIT;

        // This will allow restricted access to minters.
        minters[_typeID] = msg.sender;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), _typeID, 0);

        if (bytes(_metaLink).length > 0) metalinks[_typeID] = _metaLink;
        emit URI(_metaLink, _typeID);
    }

    /**
        @notice Get the total supply of a Credit.
        @param _typeID   ID of the Credit type
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _typeID) external view returns (uint256) {
        return totalSupplies[_typeID];
    }

    function mintNonFungible(uint256 _typeID, address[] calldata _tos)
        external
        minterOnly(_typeID)
    {
        // No need to check this is a nf type rather than an typeID since
        // minterOnly() will only let a type pass through.
        require(isNonFungible(_typeID));

        // Index are 1-based.
        uint256 index = maxIndex[_typeID] + 1;
        maxIndex[_typeID] = _tos.length.add(maxIndex[_typeID]);

        for (uint256 i = 0; i < _tos.length; ++i) {
            address to = _tos[i];
            uint256 typeID = _typeID | (index + i);

            nfOwners[typeID] = to;
            balances[_typeID][to] = balances[_typeID][to].add(1);
            totalSupplies[_typeID] = totalSupplies[_typeID].add(1);
            totalSupplies[typeID] = totalSupplies[typeID].add(1);

            emit TransferSingle(msg.sender, address(0x0), to, typeID, 1);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(
                    msg.sender,
                    msg.sender,
                    to,
                    typeID,
                    1,
                    ""
                );
            }

        }
    }

    function mintFungible(
        uint256 _typeID,
        address[] calldata _tos,
        uint256[] calldata _values
    ) external minterOnly(_typeID) {
        require(isFungible(_typeID));
        require(
            _tos.length == _values.length,
            "Credit: Array length must match"
        );

        for (uint256 i = 0; i < _tos.length; ++i) {
            address to = _tos[i];
            uint256 value = _values[i];

            // Grant the items to the caller
            balances[_typeID][to] = value.add(balances[_typeID][to]);
            totalSupplies[_typeID] = totalSupplies[_typeID].add(value);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _typeID, value);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(
                    msg.sender,
                    msg.sender,
                    to,
                    _typeID,
                    value,
                    ""
                );
            }
        }
    }

    /**
        Delete `_value` of Credit `_itemID` from the world.
        @param _itemID  Item of non-fungible credit type
        @param _from Source address
    */
    function burnNonFungible(uint256 _itemID, address _from) external {
        require(
            isNonFungible(_itemID),
            "Credit: asset being burned is not a non-fungible asset"
        );
        require(
            isNonFungibleItem(_itemID),
            "Credit: asset being burned is not a non-fungible item id"
        );
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Credit: Need operator approval for 3rd party transfers."
        );

        uint256 _type = this.getNonFungibleBaseType(_itemID);
        nfOwners[_itemID] = address(0);
        balances[_type][_from] = balances[_type][_from].sub(1);
        totalSupplies[_type] = totalSupplies[_type].sub(1);
        totalSupplies[_itemID] = totalSupplies[_itemID].sub(1);

        emit TransferSingle(msg.sender, _from, address(0), _itemID, 1);
    }

    /**
        Delete `_value` of Credit `_typeID` from the world.
        @param _typeID  Credit type
        @param _value Burn Credit quantities
        @param _from Source address
    */
    function burnFungible(uint256 _typeID, address _from, uint256 _value)
        external
    {
        require(isFungible(_typeID));
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Credit: Need operator approval for 3rd party transfers."
        );

        balances[_typeID][_from] = balances[_typeID][_from].sub(_value);
        totalSupplies[_typeID] = totalSupplies[_typeID].sub(_value);

        emit TransferSingle(msg.sender, _from, address(0), _typeID, _value);
    }

    /**
        give `_type` creator authorized to `_minter`.
        @param _typeID  Credit _typeID (when credit is fungible) or _type (when credit is non-fungible)
        @param _to New minter, in case of address 0 the authorized will be locked forever
    */
    function setMinter(uint256 _typeID, address _to)
        external
        minterOnly(_typeID)
    {
        require(
            minters[_typeID] != _to,
            "Credit: cannot set current minter as a new minter"
        );
        minters[_typeID] = _to;

        emit SetMinter(_typeID, _to);
    }
}
