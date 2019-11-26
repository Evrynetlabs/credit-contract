pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestMintNonFungible {

    ERC1155e private credit;
    address[] private testAccounts;
    bool private isNF;
    bool private result;
    uint256 private contractType;
    ERC1155e private proxyCredit;
    PayableThrowProxy private throwProxy;
    string private uri;

    function beforeEach() external {
        credit = new ERC1155e();
        uri = "foo";
        testAccounts = new address[](0);
        isNF = true;
        result = false;
        contractType = credit.create(uri, isNF);
        testAccounts.push(address(1));
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = ERC1155e(address(throwProxy));
    }


    function testBatch() external {
        uint256 expectedBal = 5;
        address addr = address(1);

        for (uint256 i = 1; i < 5; ++i) {
            testAccounts.push(addr);
        }

         for (uint256 i = 5; i < 10; ++i) {
            testAccounts.push(address(i));
        }

        credit.mintNonFungible(contractType, testAccounts);

        Assert.equal(credit.balanceOf(addr, contractType), expectedBal, "balance of address 1 should be 5");

        for (uint256 i = 0; i < 10; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], contractType + i + 1), 1, "balance of address 5 - 10 of each credit should be 1"); 
        }
    }

    function testWhenMinterHasNoPermission() external {
        credit.setMinter(contractType, address(2));
        proxyCredit.mintNonFungible(contractType, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenTypeIsFungible() external {
        isNF = false;
        contractType = credit.create(uri, isNF);
        credit.setMinter(contractType, address(proxyCredit));
        proxyCredit.mintNonFungible(contractType, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }

    function testWhenMinterHasPermission() external {
        credit.setMinter(contractType, address(proxyCredit));
        proxyCredit.mintNonFungible(contractType, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isTrue(result, "should pass creatorOnly modifier");
        Assert.equal(credit.balanceOf(testAccounts[0], contractType + 1), 1, "balance should be equal to 1");
    }

    function testWhenNotImplementOnERC1155Received() external {
        ThrowProxy _throwProxy = new ThrowProxy(address(credit));
        ERC1155e _proxyCredit = ERC1155e(address(_throwProxy));
        testAccounts[0] = address(_proxyCredit);
        credit.setMinter(contractType, address(_proxyCredit));
        _proxyCredit.mintNonFungible(contractType, testAccounts);
        (result, ) = _throwProxy.execute();

        Assert.isFalse(result, "should not pass since the contract destination doesn't implement onERC1155Received");
    }
}
