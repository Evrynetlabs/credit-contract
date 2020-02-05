pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EER2B.sol";
import "./utils/PayableThrowProxy.sol";

contract TestSetMinter {
    EER2B private credit;
    string private uri;
    bool private isNF;
    bool private result;
    PayableThrowProxy private throwProxy;
    EER2B private proxyCredit;
    uint256 id;

    function beforeEach() external {
        credit = new EER2B();
        uri = "foo";
        isNF = false;
        result = false;
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
        id = credit.create(uri, isNF);
    }

    function testWhenCallerHasNoPermission() external {
        proxyCredit.setMinter(id, address(2));
        (result, ) = throwProxy.execute();

        Assert.isFalse(
            result,
            "Should not pass since a caller is not a creator of the credit"
        );
    }

    function testWhenNewMinterIsCurrentMinter() external {
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.setMinter(id, address(proxyCredit));
        (result, ) = throwProxy.execute();

        Assert.isFalse(
            result,
            "Should not pass since a new minter cannot be a current minter (creator by default)"
        );
    }

    function testWhenMinterIsANewMinter() external {
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.setMinter(id, address(1));
        (result, ) = throwProxy.execute();

        Assert.isTrue(
            result,
            "Should pass since a new minter (address 1) is not a current minter (address(proxyCredit))"
        );
        Assert.equal(
            credit.minters(id),
            address(1),
            "should pass since minter has beeen set to address 1"
        );
    }
}
