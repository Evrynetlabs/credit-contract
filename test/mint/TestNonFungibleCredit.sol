pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestNonFungibleCredit {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenMinterIsNotACreator() external {
        string memory uri = "foo";
        bool isNF = true;
        bool result;
        address[] memory testAccounts = new address[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(2));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenTypeIsFungible() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        address[] memory testAccounts = new address[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }

    function testWhenMinterIsACreator() external {
        string memory uri = "foo";
        bool isNF = true;
        bool result;
        address[] memory testAccounts = new address[](1);
        testAccounts[0] = 0x99238cAa2d58628742db0F826B918EAC100F3B4f;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isTrue(result, "should not pass creatorOnly modifier");
        Assert.equal(credit.balanceOf(testAccounts[0], _type | 1), 1, "balance should be equal to 1");
    }
}
