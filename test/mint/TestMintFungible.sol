pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestMintFungible {

    ERC1155e private credit;
    address[] private testAccounts;
    uint256[] private quantities;
    bool private isNF;
    bool private result;
    uint256 private id;
    ERC1155e private proxyCredit;
    PayableThrowProxy private throwProxy;
    string private uri;

    function beforeEach() external {
        credit = new ERC1155e();
        uri = "foo";
        testAccounts = new address[](0);
        quantities = new uint256[](0);
        isNF = false;
        result = false;
        id = credit.create(uri, isNF);
        testAccounts.push(address(1));
        quantities.push(1);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = ERC1155e(address(throwProxy));
    }

    function testWhenMinterHasNoPermission() external {
        credit.setMinter(id, testAccounts[0]);
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenMinterHasPermission() external {
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();
        
        Assert.isTrue(result, "should successfully minting a credit");
        Assert.equal(credit.balanceOf(testAccounts[0], id), quantities[0], "balance should be equal to 1");
        Assert.equal(credit.totalSupply(id), quantities[0], "total supply of fungible type should be equal to the expected quantity");
    }

    function testBatch() external {
        uint256 expectedBal = 5;
        address addr = address(1);

        for (uint256 i = 1; i < 5; ++i) {
            testAccounts.push(addr);
            quantities.push(1);
        }

        for (uint256 i = 5; i < 10; ++i) {
            testAccounts.push(address(i));
            quantities.push(1);
        }

        credit.mintFungible(id, testAccounts, quantities);

        Assert.equal(credit.balanceOf(addr, id), expectedBal, "balance of address 1 should be 5");

        for (uint256 i = 5; i < 10; ++i) {
            Assert.equal(credit.balanceOf(testAccounts[i], id), 1, "balance of address 5 - 10 of each credit should be 1"); 
        }
        Assert.equal(credit.totalSupply(id), 10, "the total supply of fungible credit type should be the expected quantity multiply with many test accounts");
    }

    function testWhenTypeIsNotFungible() external {
        isNF = true;
        id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }

    function testWhenTosAndQuantititesLengthAreUnequal() external {
        testAccounts.push(address(2));
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass length comparison");
    }

    function testWhenNotImplementOnERC1155Received() external {
        ThrowProxy _throwProxy = new ThrowProxy(address(credit));
        ERC1155e _proxyCredit = ERC1155e(address(_throwProxy));
        testAccounts[0] = address(_proxyCredit);
        credit.setMinter(id, address(_proxyCredit));
        _proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = _throwProxy.execute();

        Assert.isFalse(result, "should not pass since the contract destination doesn't implement onERC1155Received");
    }
}
