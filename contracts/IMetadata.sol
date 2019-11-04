pragma solidity ^0.5.0;

interface IMetadata {

    function name(uint256 _id) view external returns(string memory);

    function code(uint256 _id) view external returns(string memory);

    function issuer(uint256 _id) view external returns(string memory);

    function decimals(uint256 _id) view external returns(uint16);

    function jsonURL(uint256 _id) view external returns(string memory);
}

