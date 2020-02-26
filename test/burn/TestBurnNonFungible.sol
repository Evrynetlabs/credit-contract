pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";


contract TestBurnNonFungible {
    EER2B private credit;
    string private uri;
    bool private isNF;
    uint256 private typeID;
    bool private result;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    EER2B private proxyCredit;

    function beforeEach() external {
        credit = new EER2B();
        uri = "foo";
        isNF = true;
        result = false;
        typeID = credit.create(uri, isNF);
        testAccounts = new address[](0);
        testAccounts.push(address(1));
        quantities = new uint256[](0);
        quantities.push(1);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
    }

    function testWhenCreditIsFungible() external {
        isNF = false;
        typeID = credit.create(uri, isNF);
        credit.mintFungible(typeID, testAccounts, quantities);

        proxyCredit.burnNonFungible(typeID, testAccounts[0]);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since the type of credit is fungible");
    }

    function testWhenCallerHasNoPermission() external {
        credit.mintNonFungible(typeID, testAccounts);

        proxyCredit.burnNonFungible(typeID | 1, testAccounts[0]);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since the caller is not the owner of credit id");
    }

    function testWhenBurnedCreditIsNotItemID() external {
        testAccounts[0] = address(proxyCredit);
        credit.mintNonFungible(typeID, testAccounts);

        proxyCredit.burnNonFungible(typeID, testAccounts[0]);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since the burned credit is not item id");
    }

    function testWhenSuccess() external {
        testAccounts[0] = address(proxyCredit);
        credit.mintNonFungible(typeID, testAccounts);

        proxyCredit.burnNonFungible(typeID + 1, testAccounts[0]);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since credit is fungible");
        Assert.equal(
            credit.balanceOf(testAccounts[0], typeID),
            0,
            "the balance of this credit id/type after being burned should be 0"
        );
        Assert.equal(
            credit.balanceOf(testAccounts[0], typeID + 1),
            0,
            "the balance of this credit id/type after being burned should be 0"
        );
        Assert.equal(
            credit.totalSupply(typeID),
            0,
            "the total supply of non-fungible credit type should be decreased"
        );
        Assert.equal(
            credit.totalSupply(typeID + 1),
            0,
            "the total supply of non-fungible credit id should be decreased"
        );
    }
}
