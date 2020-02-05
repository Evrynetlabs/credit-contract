pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "./utils/ThrowProxy.sol";
import "../contracts/EER2A.sol";

contract TestApproval {
    EER2A private credit;
    ThrowProxy private accountProxy;
    address private fooAccount;
    address private barAccount = address(1);

    function testApproval() external {
        credit = new EER2A();
        accountProxy = new ThrowProxy(address(credit));
        fooAccount = address(accountProxy);

        Assert.isFalse(
            credit.isApprovedForAll(fooAccount, barAccount),
            "fooAccount should not have permission on barAccount"
        );
        Assert.isFalse(
            credit.isApprovedForAll(barAccount, fooAccount),
            "barAccount should not have permission on fooAccount"
        );

        EER2A(fooAccount).setApprovalForAll(barAccount, true);
        (bool success, ) = accountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error granting permission");

        Assert.isTrue(
            credit.isApprovedForAll(fooAccount, barAccount),
            "fooAccount should have permission on barAccount"
        );
        Assert.isFalse(
            credit.isApprovedForAll(barAccount, fooAccount),
            "barAccount should not have permission on fooAccount"
        );

        EER2A(fooAccount).setApprovalForAll(barAccount, false);
        (success, ) = accountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error revoking permission");

        Assert.isFalse(
            credit.isApprovedForAll(fooAccount, barAccount),
            "fooAccount permission should be revoked"
        );
        Assert.isFalse(
            credit.isApprovedForAll(barAccount, fooAccount),
            "barAccount should not have permission on fooAccount"
        );
    }
}
