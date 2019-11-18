pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestFungibleCreditCreator {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenMinterIsNotACreator() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        address[] memory testAccounts = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        quantities[0] = 1;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, testAccounts[0]);
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenMinterIsACreator() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        address[] memory testAccounts = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        quantities[0] = 1;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();
        
        Assert.isTrue(result, "should pass creatorOnly modifier");
        Assert.equal(credit.balanceOf(testAccounts[0], id), quantities[0], "balance should be equal to 1");
    }
}
