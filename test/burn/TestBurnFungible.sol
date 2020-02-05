pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";

contract TestBurnFungible {
    EER2B private credit;
    string private uri;
    bool private isNF;
    uint256 private id;
    bool private result;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    EER2B private proxyCredit;

    function beforeEach() external {
        credit = new EER2B();
        uri = "foo";
        isNF = false;
        result = false;
        id = credit.create(uri, isNF);
        testAccounts = new address[](0);
        testAccounts.push(address(1));
        quantities = new uint256[](0);
        quantities.push(1);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
    }

    function testWhenCreditIsNonFungible() external {
        isNF = true;
        id = credit.create(uri, isNF);
        credit.mintNonFungible(id, testAccounts);

        proxyCredit.burnFungible(id, testAccounts[0], 1);
        (result, ) = throwProxy.execute();
        Assert.isFalse(
            result,
            "should not pass since type of credit is non fungible"
        );
    }

    function testWhenCallerHasNoPermission() external {
        credit.mintFungible(id, testAccounts, quantities);

        proxyCredit.burnFungible(id, testAccounts[0], 1);
        (result, ) = throwProxy.execute();
        Assert.isFalse(
            result,
            "should not pass since the caller is not the owner of credit id"
        );
    }

    function testWhenSuccess() external {
        testAccounts[0] = address(proxyCredit);
        credit.mintFungible(id, testAccounts, quantities);

        proxyCredit.burnFungible(id, testAccounts[0], 1);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since credit is fungible");
        Assert.equal(
            credit.balanceOf(testAccounts[0], id),
            0,
            "the balance of this credit id/type after being burned should be 0"
        );
        Assert.equal(
            credit.totalSupply(id),
            0,
            "the total supply of this credit id/type after being burned should be decreased"
        );
    }

    function testWhenInsufficientCredit() external {
        proxyCredit.burnFungible(id, testAccounts[0], 1);
        (result, ) = throwProxy.execute();
        Assert.isFalse(
            result,
            "should not pass since credit quantity is less than 1"
        );
    }

}
