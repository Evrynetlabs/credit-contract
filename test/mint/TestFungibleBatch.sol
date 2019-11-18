pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";

contract TestFungibleBatch {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenAddressesAreTheSame() external {
        uint256 expectedBal;
        address addr = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        address[] memory testAccounts = new address[](5);
        uint256[] memory quantities = new uint256[](5);

        for (uint256 i = 0; i < 5; ++i) {
            testAccounts[i] = addr;
            quantities[i] = 1;
            expectedBal++; 
        }

        string memory uri = "foo";
        bool isNF = false;
        
        uint256 id = credit.create(uri, isNF);
        credit.mintFungible(id, testAccounts, quantities);

        Assert.equal(credit.balanceOf(addr, id), expectedBal, "balance should be as expected");
    }

    function testWhenAddressesAreDifferent() external {
        uint256 expectedBal;
        address[] memory testAccounts = new address[](5);
        uint256[] memory quantities = new uint256[](5);
        for (uint256 i = 0; i < 5; ++i) {
            testAccounts[i] = address(i);
            quantities[i] = 1;
            expectedBal++; 
        }

        string memory uri = "foo";
        bool isNF = false;
        
        uint256 id = credit.create(uri, isNF);
        credit.mintFungible(id, testAccounts, quantities);

        for (uint256 i = 0; i < 5; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], id), 1, "owner of each credit should be as expected"); 
        }
    }
}
