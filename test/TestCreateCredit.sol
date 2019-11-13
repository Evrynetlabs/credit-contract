pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC1155MixedFungibleMintable.sol";

contract TestCreateCredit {

    ERC1155MixedFungibleMintable private credit;

    function beforeEach() external {
      credit = new ERC1155MixedFungibleMintable();
    }

    function testCreateFungibleTypes() external {
        string memory expectedURI = "foo";
        bool isNF = false;
        uint256 expectedID = 1 << 128;
        credit.create(expectedURI, isNF);
        Assert.isTrue(credit.isFungible(expectedID), "credit type should be non-fundgible");
        Assert.equal(credit.creators(expectedID), msg.sender, "message sender should be the one who created the type");
    }

    // function testCreateNFTypes() external {
    //     string memory expectedURI = "foo";
    //     bool isNF = false;
    //     uint256 expectedID = 1 << 128 | ;
    //     credit.create(expectedURI, isNF);
    //     Assert.isTrue(credit.isNonFungible(expectedID), "credit type should be non-fundgible");
    //     Assert.equal(credit.creators(expectedID), msg.sender, "message sender should be the one who created the type");
    // }
}
