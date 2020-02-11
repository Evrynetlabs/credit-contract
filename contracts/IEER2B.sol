pragma solidity ^0.5.0;

interface IEER2B {
    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "EER-2 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _typeID);

    /**
        @dev MUST emit when creator authorized to `_minter`. 
     */
    event SetMinter(uint256 indexed _typeID, address _minter);

    /**
        give `_typeID` creator authorized to `_minter`.
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
        Delete `_value` of Credit `_itemID` from the world.
        @param _itemID  Item of non-fungible credit type
        @param _from Source address
    */
    function burnNonFungible(uint256 _itemID, address _from) external;

    /**
        Delete `_value` of Credit `_typeID` from the world.
        @param _typeID  Credit type
        @param _value Burn Credit quantities
        @param _from Source address
    */
    function burnFungible(uint256 _typeID, address _from, uint256 _value)
        external;
}
