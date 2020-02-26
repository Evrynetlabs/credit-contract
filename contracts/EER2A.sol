pragma solidity ^0.5.0;

import "./IEER2A.sol";
import "./IEER2TokenReceiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract EER2A is IEER2A {
    using SafeMath for uint256;
    using Address for address;

    bytes4 internal constant EER2_ACCEPTED = 0x09a23c29; // bytes4(keccak256("onEER2Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant EER2_BATCH_ACCEPTED = 0xbaf5f228; // bytes4(keccak256("onEER2BatchReceived(address,address,uint256[],uint256[],bytes)"))

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = uint128(~0);

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    uint256 nonce;
    mapping(uint256 => address) public minters;
    mapping(uint256 => address) nfOwners;
    mapping(uint256 => string) public metalinks;
    mapping(uint256 => uint256) public maxIndex;
    mapping(uint256 => uint256) public totalSupplies;

    // typeID => (owner => balance)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping(address => mapping(address => bool)) internal operatorApproval;

    // Only to make code clearer. Should not be functions
    function isNonFungible(uint256 _typeID) public pure returns (bool) {
        return _typeID & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _typeID) public pure returns (bool) {
        return _typeID & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _itemID) public pure returns (uint256) {
        return _itemID & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _itemID) public pure returns (uint256) {
        return _itemID & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _typeID) public pure returns (bool) {
        // A base type has the NF bit but does not have an index.
        return isNonFungible(_typeID) && getNonFungibleIndex(_typeID) == 0;
    }

    function isNonFungibleItem(uint256 itemID) public pure returns (bool) {
        // A base type has the NF bit but does has an index.
        return isNonFungible(itemID) && (itemID & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _itemID) public view returns (address) {
        return nfOwners[_itemID];
    }

    modifier minterOnly(uint256 _typeID) {
        require(minters[_typeID] == msg.sender);
        _;
    }

    /**
        @notice Get the balance of an account's Tokens.
        @dev EER2 balanceOf function
        @param _owner  The address of the token holder
        @param _typeID ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _typeID) public view returns (uint256) {
        if (isNonFungibleItem(_typeID)) {
            return nfOwners[_typeID] == _owner ? 1 : 0;
        }
        return balances[_typeID][_owner];
    }

    function metaLink(uint256 _typeID) external view returns (string memory) {
        return metalinks[_typeID];
    }

    /**
        @notice Get the balance of multiple account/token pairs (override)
        @dev EER2 balanceOfBatch function
        @param _owners The addresses of the token holders
        @param _typeIDs ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, typeID) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _typeIDs)
        external
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _typeIDs.length, "Credit: Array length must match");

        uint256[] memory _balances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            _balances[i] = balanceOf(_owners[i], _typeIDs[i]);
        }
        return _balances;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    /**
        @notice Transfers `_value` amount of an `_typeID` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account.
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_typeID` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event. 
        @param _from    Source address
        @param _to      Target address
        @param _typeID  ID of the token type
        @param _value   Transfer amount
        @param _data    Data sending to event logs
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _typeID,
        uint256 _value,
        bytes calldata _data
    ) external {
        require(_to != address(0x0), "Credit: cannot send to zero address");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Credit: Need operator approval for 3rd party transfers."
        );

        if (isNonFungible(_typeID)) {
            require(nfOwners[_typeID] == _from);
            nfOwners[_typeID] = _to;

            uint256 baseType = getNonFungibleBaseType(_typeID);
            balances[baseType][_from] = balances[baseType][_from].sub(_value);
            balances[baseType][_to] = balances[baseType][_to].add(_value);
        } else {
            // SafeMath will throw with insufficient funds _from
            // or if _typeID is not valid (balance will be 0)
            balances[_typeID][_from] = balances[_typeID][_from].sub(_value);
            balances[_typeID][_to] = balances[_typeID][_to].add(_value);
        }

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _typeID, _value);

        // Now that the balance is updated and the event was emitted,
        // call onEER2Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _typeID, _value, _data);
        }
    }

    /**
        @notice Transfers `_values` amount(s) of `_typeIDs` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account.
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_typeIDs` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_typeIDs` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s).
        @param _from    Source address
        @param _to      Target address
        @param _typeIDs IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _typeIDs array)
        @param _data    Data sending to event logs
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _typeIDs,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        require(_to != address(0x0), "cannot send to zero address");
        require(_typeIDs.length == _values.length, "Array length must match");

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < _typeIDs.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 typeID = _typeIDs[i];
            uint256 value = _values[i];

            if (isNonFungible(typeID)) {
                require(nfOwners[typeID] == _from);
                nfOwners[typeID] = _to;
                uint256 baseType = getNonFungibleBaseType(typeID);
                balances[baseType][_from] = balances[baseType][_from].sub(1);
                balances[baseType][_to] = balances[baseType][_to].add(1);
            } else {
                balances[typeID][_from] = balances[typeID][_from].sub(value);
                balances[typeID][_to] = value.add(balances[typeID][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _typeIDs, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _typeIDs, _values, _data);
        }
    }

    /**
        Multiple transfer with [multi-sender] [multi-receiver] and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_typeID` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_typeID` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement EER2TokenReceiver.
        MUST be revert if number of `_froms` `_tos` `_typeIDs` and `_values` does not eqaul.
        MUST emit TransferFullBatch event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _typeIDs  List of ID of the credit types
        @param _values   List of Transfer amounts
        @param _data     Data sending to event logs
    */
    function safeFullBatchTransferFrom(
        address[] calldata _froms,
        address[] calldata _tos,
        uint256[] calldata _typeIDs,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        require(
            _froms.length == _tos.length &&
                _froms.length == _typeIDs.length &&
                _froms.length == _values.length,
            "Credit: Array length must match"
        );

        for (uint256 i = 0; i < _froms.length; ++i) {
            // Cache value to local variable to reduce read costs.
            address from = _froms[i];
            address to = _tos[i];
            uint256 typeID = _typeIDs[i];
            uint256 value = _values[i];

            require(to != address(0x0), "Credit: cannot send to zero address");
            require(
                from == msg.sender || operatorApproval[from][msg.sender] == true,
                "Credit: Need operator approval for 3rd party transfers."
            );
            if (isNonFungible(typeID)) {
                require(nfOwners[typeID] == from);
                uint256 baseType = getNonFungibleBaseType(typeID);
                nfOwners[typeID] = to;
                balances[baseType][from] = balances[baseType][from].sub(1);
                balances[baseType][to] = balances[baseType][to].add(1);
            } else {
                balances[typeID][from] = balances[typeID][from].sub(value);
                balances[typeID][to] = value.add(balances[typeID][to]);
            }
            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, from, to, typeID, value, _data);
            }
        }

        emit TransferFullBatch(msg.sender, _froms, _tos, _typeIDs, _values, _data);
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _typeID,
        uint256 _value,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an EER-2 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onEER2Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the EER2_ACCEPTED test.
        require(
            IEER2TokenReceiver(_to).onEER2Received(_operator, _from, _typeID, _value, _data) ==
                EER2_ACCEPTED,
            "contract returned an unknown value from onEER2Received"
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _typeIDs,
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an EER-2 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onEER2BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the EER2_BATCH_ACCEPTED test.
        require(
            IEER2TokenReceiver(_to).onEER2BatchReceived(
                _operator,
                _from,
                _typeIDs,
                _values,
                _data
            ) ==
                EER2_BATCH_ACCEPTED,
            "contract returned an unknown value from onEER2BatchReceived"
        );
    }
}
