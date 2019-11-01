pragma solidity ^0.5.0;

interface Metadata {
    
    event Register(uint256 indexed _id);
    
    function register(uint256 _id, string calldata name, string calldata code, string calldata issuer, string calldata jsonURL, uint16 decimals) external;
    
    function name(uint256 _id) view external returns(string memory);
    function code(uint256 _id) view external returns(string memory);
    function issuer(uint256 _id) view external returns(string memory);
    function decimals(uint256 _id) view external returns(uint16);
    function jsonURL(uint256 _id) view external returns(string memory);
}

