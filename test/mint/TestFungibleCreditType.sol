pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/ThrowProxy.sol";

contract TestFungibleCreditType {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenTypeIsNotFungible() external {
        string memory uri = "foo";
        bool isNF = true;
        bool result;
        address[] memory testAccounts = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        quantities[0] = 1;
        ThrowProxy throwProxy = new ThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }
}
