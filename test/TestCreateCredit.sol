pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC1155e.sol";

contract TestCreateCredit {

    ERC1155E private credit;

    function beforeEach() external {
      credit = new ERC1155E();
    }

    function testCreateFungibleTypes() external {
        string memory expectedURI = "foo";
        bool isNF = false;
        uint256 expectedID = 1 << 128;
        uint256 actualID = credit.create(expectedURI, isNF);
        Assert.isTrue(credit.isFungible(expectedID), "credit type should be non-fundgible");
        Assert.equal(actualID, expectedID, "ID from create function should be equal to expected ID");
        Assert.equal(credit.creators(actualID), address(this), "address creator should be this contract address");
    }

    function testCreateNFTypes() external {
        string memory expectedURI = "foo";
        bool isNF = true;
        uint256 expectedID = 1 << 128 | 1 << 255 ;
        uint256 actualID = credit.create(expectedURI, isNF);
        Assert.isTrue(credit.isNonFungible(expectedID), "credit type should be non-fundgible");
        Assert.equal(actualID, expectedID, "ID from create function should be equal to expected ID");
        Assert.equal(credit.creators(actualID), address(this), "address creator should be this contract address");
    }
}
