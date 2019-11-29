pragma solidity ^0.5.0;

interface IERC1155e /* is ERC1155MixedFungibleMintable, IERC1155Metadata */ {

    /**
        @dev Either `TransferFullBatch` MUST emit when tokens are transferred using full batch transfer.
        The `_operator` argument MUST be msg.sender.
        The `_froms` argument MUST be the addresses of the holder whose balance is decreased.
        The `_tos` argument MUST be the addresses of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        The `_key` argument MUST be a data or key for indexing the event log.
    */
    event TransferFullBatch(address indexed _operator, address[] _froms, address[] _tos, uint256[] _ids, uint256[] _values, bytes indexed _key);
    event Create(uint256 indexed _id, address _creator);
    event SetMinter(uint256 indexed _type, address _minter);

    /**
        Multiple transfer with [multi-sender] [multi-receiver] and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement IReceiver.
        MUST be revert if number of `_froms` `_tos` `_ids` and `_values` does not eqaul.
        MUST emit TransferFullBatch event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _ids      List of ID of the credit types
        @param _values   List of Transfer amounts
    */
    function safeFullBatchTransferFrom(address[] calldata _froms, address[] calldata _tos, uint256[] calldata _ids, uint256[]
                                   calldata _values, bytes calldata _data) external;
    
    /**
        give `_id` creator authorized to `_minter`.
        @param _type  Credit type
        @param _minter New minter, in case of address 0 the authorized will be locked forever
    */
    function setMinter(uint256 _type, address _minter) external;

    /**
        @notice Get the total supply of a Credit.
        @param _id     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _id) view external returns(uint256);
}
