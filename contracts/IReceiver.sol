pragma solidity ^0.5.0;

interface Receiver {
    function creditable(uint256 id) pure external returns(bool);
}

