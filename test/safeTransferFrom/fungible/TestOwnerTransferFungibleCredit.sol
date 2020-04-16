pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../../utils/ThrowProxy.sol";
import "../../utils/PayableThrowProxy.sol";
import "../../../contracts/EER2B.sol";


contract TestOwnerTransferFungibleCredit {
    EER2B private credit;
    PayableThrowProxy private fooAccountProxy;
    address private fooAccount;
    uint256 private initialCreditBalance = 100;
    uint256 private transferringAmount = 30;

    function beforeEach() external {
        credit = new EER2B();
        fooAccountProxy = new PayableThrowProxy(address(credit));
        fooAccount = address(fooAccountProxy);
    }

    function prepareFungible() internal returns (uint256) {
        uint256 fungibleCreditID = credit.create("", false);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;
        uint256[] memory quantities = new uint256[](1);
        quantities[0] = initialCreditBalance;

        credit.mintFungible(fungibleCreditID, tos, quantities);
        return fungibleCreditID;
    }

    function testTransferFungibleCreditToAccount() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(
            initialFooAccountBalance,
            initialCreditBalance,
            "account should have an initial balance of credit"
        );
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        EER2B(fooAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            fungibleCreditID,
            transferringAmount,
            bytes("")
        );
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(
            initialFooAccountBalance - transferringAmount,
            remainingFooAccountBalance,
            "foo account balance should decreased per transferred amount"
        );
        Assert.equal(
            initialBarAccountBalance + transferringAmount,
            remainingBarAccountBalance,
            "bar account balance should increased per transferred amount"
        );
    }

    function testTransferFungibleCreditToTokenReceivedContract() external {
        uint256 fungibleCreditID = prepareFungible();
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(
            initialFooAccountBalance,
            initialCreditBalance,
            "account should have an initial balance of credit"
        );
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        EER2B(fooAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            fungibleCreditID,
            transferringAmount,
            bytes("")
        );
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(
            initialFooAccountBalance - transferringAmount,
            remainingFooAccountBalance,
            "foo account balance should decreased per transferred amount"
        );
        Assert.equal(
            initialBarAccountBalance + transferringAmount,
            remainingBarAccountBalance,
            "bar account balance should increased per transferred amount"
        );
    }
}
