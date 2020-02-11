pragma solidity ^0.5.0;

interface IEER2A {
    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning .
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_typeID` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _typeID,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning .
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_typeIDs` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _typeIDs) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _typeIDs,
        uint256[] _values
    );

    /**
        @dev `TransferFullBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning .
        The `_operator` argument MUST be msg.sender.
        The `_froms` argument MUST be the  list of address of the holder whose balance is decreased.
        The `_tos` argument MUST be the list of address of the recipient whose balance is increased.
        The `_typeIDs` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _typeIDs) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_froms` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_tos` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferFullBatch(
        address indexed _operator,
        address[] _froms,
        address[] _tos,
        uint256[] _typeIDs,
        uint256[] _values,
        bytes indexed _key
    );

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
    ) external;

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
    ) external;

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
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _typeID     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _typeID)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _typeIDs    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, typeID) pair)
     */
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _typeIDs
    ) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    /** 
        @notice Get the owner of the n non-fungible credit
        @param _itemID the item id of the non-fungible credit
        @return The owner of the non-fungible credit
    */
    function ownerOf(uint256 _itemID) external view returns (address);

    /** 
        @notice Get contract address of metalink
        @param _typeID ID of the credit type
        @return contract address of metalink
    */
    function metaLink(uint256 _typeID) external view returns (string memory);
}
