pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/ThrowProxy.sol";

contract TestNonFungibleBatch {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenAddressesAreTheSame() external {
        uint256 expectedBal;
        address addr = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        address[] memory testAccounts = new address[](5);

        for (uint256 i = 0; i < 5; ++i) {
            testAccounts[i] = addr;
            expectedBal++; 
        }

        string memory uri = "foo";
        bool isNF = true;
        
        uint256 _type = credit.create(uri, isNF);
        credit.mintNonFungible(_type, testAccounts);

        for (uint256 i = 0; i < 5; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], _type | i + 1 ), 1, "owner of each credit should be as expected"); 
        }

        Assert.equal(credit.balanceOf(addr, _type), expectedBal, "balance of type should be as expected");
    }

    function testWhenAddressesAreDifferent() external {
        uint256 expectedBal;
        address[] memory testAccounts = new address[](5);

        for (uint256 i = 0; i < 5; ++i) {
            testAccounts[i] = address(i);
            expectedBal++; 
        }

        string memory uri = "foo";
        bool isNF = true;
        
        uint256 _type = credit.create(uri, isNF);
        credit.mintNonFungible(_type, testAccounts);

        for (uint256 i = 0; i < 5; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], _type | i + 1 ), 1, "owner of each credit should be as expected"); 
        }
    }
}
