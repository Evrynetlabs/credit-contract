pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";


contract TestMintFungible {
    EER2B private credit;
    address[] private testAccounts;
    uint256[] private quantities;
    bool private isNF;
    bool private result;
    uint256 private typeID;
    EER2B private proxyCredit;
    PayableThrowProxy private throwProxy;
    string private uri;

    function beforeEach() external {
        credit = new EER2B();
        uri = "foo";
        testAccounts = new address[](0);
        quantities = new uint256[](0);
        isNF = false;
        result = false;
        typeID = credit.create(uri, isNF);
        testAccounts.push(address(1));
        quantities.push(1);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
    }

    function testWhenMinterHasNoPermission() external {
        credit.setMinter(typeID, testAccounts[0]);
        proxyCredit.mintFungible(typeID, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass creatorOnly modifier");
    }

    function testWhenMinterHasPermission() external {
        credit.setMinter(typeID, address(proxyCredit));
        proxyCredit.mintFungible(typeID, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isTrue(result, "should successfully minting a credit");
        Assert.equal(
            credit.balanceOf(testAccounts[0], typeID),
            quantities[0],
            "balance should be equal to 1"
        );
        Assert.equal(
            credit.totalSupply(typeID),
            quantities[0],
            "total supply of fungible type should be equal to the expected quantity"
        );
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

        credit.mintFungible(typeID, testAccounts, quantities);

        Assert.equal(
            credit.balanceOf(addr, typeID),
            expectedBal,
            "balance of address 1 should be 5"
        );

        for (uint256 i = 5; i < 10; ++i) {
            Assert.equal(
                credit.balanceOf(testAccounts[i], typeID),
                1,
                "balance of address 5 - 10 of each credit should be 1"
            );
        }
        Assert.equal(
            credit.totalSupply(typeID),
            10,
            "the total supply of fungible credit type should be the expected quantity multiply with many test accounts"
        );
    }

    function testWhenTypeIsNotFungible() external {
        isNF = true;
        typeID = credit.create(uri, isNF);
        credit.setMinter(typeID, address(proxyCredit));
        proxyCredit.mintFungible(typeID, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass require fungible");
    }

    function testWhenTosAndQuantititesLengthAreUnequal() external {
        testAccounts.push(address(2));
        credit.setMinter(typeID, address(proxyCredit));
        proxyCredit.mintFungible(typeID, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass length comparison");
    }

    function testWhenNotImplementOnEER2Received() external {
        ThrowProxy _throwProxy = new ThrowProxy(address(credit));
        EER2B _proxyCredit = EER2B(address(_throwProxy));
        testAccounts[0] = address(_proxyCredit);
        credit.setMinter(typeID, address(_proxyCredit));
        _proxyCredit.mintFungible(typeID, testAccounts, quantities);
        (result, ) = _throwProxy.execute();

        Assert.isFalse(
            result,
            "should not pass since the contract destination doesn't implement onEER2Received"
        );
    }
}
