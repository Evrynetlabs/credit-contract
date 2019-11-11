pragma solidity ^0.5.0;

import "./enjin/ERC1155MixedFungibleMintable.sol";
import "./enjin/IERC1155Metadata.sol";

interface ICredit is ERC1155MixedFungibleMintable, IERC1155Metadata {

    event TransferFullBatch(address indexed _operator, address[] indexed _froms, address[] indexed _tos, uint256[] _ids, uint256[] _values);
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
        MUST emit FullBatchTransfer event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _ids      List of ID of the credit types
        @param _values   List of Transfer amounts
    */
    function safeFullBatchTransfer(address[] calldata _froms, address[] calldata _tos, uint256[] calldata _ids, uint256[]
                                   calldata _values, bytes calldata _data) external;

    /**
        Remove `_type` from the world.
        @param _type  Non-fungible Credit type
    */
    function burnNonFungible(uint256 _type) external;

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
        @param _quantities Burn Credit amount
    */
    function burnFungible(uint256 _id, uint256 _quantities) external;
    
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
