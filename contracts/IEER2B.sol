pragma solidity ^0.5.0;

interface IEER2B {
    /**
        @dev The URI must point either an address of the Metadata contract or a JSON file 
        that conforms to the "EER-2 Metadata URI JSON Schema"
        @param _value The string of the URI being updated for a token.
        @param _typeID The ID of token being updated.
    */
    event URI(string _value, uint256 indexed _typeID);

    /**
        @dev MUST emit when creator authorized to `_minter`. 
        @param _typeID The ID of token being updated.
        @param _minter The address which will be authorized
     */
    event SetMinter(uint256 indexed _typeID, address _minter);

    /**
        @notice Authorize `_to` address to act the minter of the `_typeID` credit type
        @param _typeID  Credit type
        @param _to New minter, in case of address 0 the authorized will be locked forever
    */
    function setMinter(uint256 _typeID, address _to) external;

    /**
        @notice Get the total supply of a Credit.
        @param _typeID     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _typeID) external view returns (uint256);

    /**
        @notice Create credit type fungible or non-fungible
        @param _metaLink contract address of metalink which keep information about credit type
        @param _isNF specific type which want to create
        @return The type id of credit type
     */
    function create(string calldata _metaLink, bool _isNF)
        external
        returns (uint256 _type);

    /**
        @notice Add item of the non-fungible credit.
        @param _typeID Credit type
        @param _tos Destination addresses
     */
    function mintNonFungible(uint256 _typeID, address[] calldata _tos) external;

    /**
        @notice Add value of the fungible credit.
        @dev Caller MUST has a minter role to mint the token
        @param _typeID Credit type
        @param _tos Destination addresses
        @param _values Mint credit quantities
     */
    function mintFungible(
        uint256 _typeID,
        address[] calldata _tos,
        uint256[] calldata _values
    ) external;

    /**
        @notice Delete a non-fungible credit with the corresponding `_itemID` 
        @dev Caller MUST be approved to manage the tokens being deleting out of the `_from` account.
        MUST revert if `_from` account does not own the item with the `_itemID` sent.
        MUST revert on any other error.
        MUST emit TransferSingle event.
        @param _itemID  Item of non-fungible credit type
        @param _from Source address
    */
    function burnNonFungible(uint256 _itemID, address _from) external;

    /**
        @notice Delete the `_value` amount of fungible credit with the corresponding `_typeID` from the `_from` account 
        @dev Caller MUST be approved to manage the tokens being deleting out of the `_from` account.
        MUST revert if the `_typeID` does not represent a fungible credit type.
        MUST revert if balance of holder for token `_typeID` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit TransferSingle event.
        @param _typeID  Credit type
        @param _value Burn Credit quantities
        @param _from Source address
    */
    function burnFungible(uint256 _typeID, address _from, uint256 _value)
        external;
}
