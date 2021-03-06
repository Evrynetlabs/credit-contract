pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EER2B.sol";

contract TestCreateCredit {
    EER2B private credit;

    function beforeEach() external {
        credit = new EER2B();
    }

    function testCreateFungibleTypes() external {
        string memory expectedURI = "foo";
        bool isNF = false;
        uint256 expectedID = 1 << 128;
        uint256 actualID = credit.create(expectedURI, isNF);
        Assert.isTrue(
            credit.isFungible(expectedID),
            "credit type should be non-fundgible"
        );
        Assert.equal(
            actualID,
            expectedID,
            "ID from create function should be equal to expected ID"
        );
        Assert.equal(
            credit.minters(actualID),
            address(this),
            "address creator should be this contract address"
        );
        Assert.equal(
            credit.metaLink(actualID),
            expectedURI,
            "metalink should be equal to expected URI"
        );
    }

    function testCreateNFTypes() external {
        string memory expectedURI = "foo";
        bool isNF = true;
        uint256 expectedID = (1 << 128) | (1 << 255);
        uint256 actualID = credit.create(expectedURI, isNF);
        Assert.isTrue(
            credit.isNonFungible(expectedID),
            "credit type should be non-fundgible"
        );
        Assert.equal(
            actualID,
            expectedID,
            "ID from create function should be equal to expected ID"
        );
        Assert.equal(
            credit.minters(actualID),
            address(this),
            "address creator should be this contract address"
        );
        Assert.equal(
            credit.metaLink(actualID),
            expectedURI,
            "metalink should be equal to expected URI"
        );
    }
}
