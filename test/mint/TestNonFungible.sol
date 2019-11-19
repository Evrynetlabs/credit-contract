pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestNonFungible {

    ERC1155E private credit;
    address[] private testAccounts;
    bool private isNF;
    bool private result;
    uint256 private _type;
    ERC1155E private proxyCredit;
    PayableThrowProxy private throwProxy;
    string private uri;

    function beforeEach() external {
        credit = new ERC1155E();
        uri = "foo";
        testAccounts = new address[](0);
        isNF = true;
        result = false;
        _type = credit.create(uri, isNF);
        testAccounts.push(address(1));
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = ERC1155E(address(throwProxy));
    }


    function testAddresses() external {
        uint256 expectedBal = 5;
        address addr = address(1);

        for (uint256 i = 1; i < 5; ++i) {
            testAccounts.push(addr);
        }

         for (uint256 i = 5; i < 10; ++i) {
            testAccounts.push(address(i));
        }

        credit.mintNonFungible(_type, testAccounts);

        Assert.equal(credit.balanceOf(addr, _type), expectedBal, "balance of address 1 should be 5");

        for (uint256 i = 0; i < 10; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], _type + i + 1), 1, "balance of address 5 - 10 of each credit should be 1"); 
        }
    }

    function testWhenMinterHasNoPermission() external {
        credit.setMinter(_type, address(2));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenTypeIsFungible() external {
        isNF = false;
        _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }

    function testWhenMinterHasPermission() external {
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isTrue(result, "should pass creatorOnly modifier");
        Assert.equal(credit.balanceOf(testAccounts[0], _type | 1), 1, "balance should be equal to 1");
    }

    function testWhenNotImplementOnERC1155Received() external {
        ThrowProxy _throwProxy = new ThrowProxy(address(credit));
        ERC1155E _proxyCredit = ERC1155E(address(_throwProxy));
        testAccounts[0] = address(_proxyCredit);
        credit.setMinter(_type, address(_proxyCredit));
        _proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = _throwProxy.execute();

        Assert.isFalse(result, "should not pass since the contract destination doesn't implement onERC1155Received");
    }
}
