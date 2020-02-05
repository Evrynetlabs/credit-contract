pragma solidity ^0.5.0;

interface IEER2B {
    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "EER-2 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);
    event SetMinter(uint256 indexed _type, address _minter);
}
