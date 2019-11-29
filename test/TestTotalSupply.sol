pragma solidity >=0.4.25 < 0.6.0;

import "truffle/Assert.sol";
import "./../contracts/ERC1155e.sol";

contract TestTotalSupply {
    ERC1155e private credit;
    address private fooAccount;
    uint256 private initialCreditBalance = 100;

    function beforeEach() external {
        credit = new ERC1155e();
    }

    function prepareFungible() internal returns(uint256) {
        uint256 fungibleCreditID = credit.create("", false);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;
        uint256[] memory quantities = new uint256[](1);
        quantities[0] = initialCreditBalance;

        credit.mintFungible(fungibleCreditID, tos, quantities);
        return fungibleCreditID;
    }

    function prepareNonFungible() internal returns(uint256) {
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;

        credit.mintNonFungible(nonFungibleCreditType, tos);
        return nonFungibleCreditType;
    }

    function testTotalSupplyOfFungibleType() external {
        uint256 fungibleCreditID = prepareFungible();

        Assert.equal(initialCreditBalance, credit.totalSupply(fungibleCreditID), "total supply of fungible credit type should be equal to the expected total amount");
    }

    function testTotalSupplyOfNonFungibleType() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 1;

        Assert.equal(1, credit.totalSupply(nonFungibleCreditType), "total supply should have a non-fungible credit type");
        Assert.equal(1, credit.totalSupply(nonFungibleCreditID), "total supply should have a non-fungible credit id");
    }
}