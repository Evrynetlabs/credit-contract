pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../../utils/ThrowProxy.sol";
import "../../utils/PayableThrowProxy.sol";
import "../../../contracts/EER2B.sol";


contract TestOperatorTransferNonFungibleCredit {
    EER2B public credit;
    PayableThrowProxy private fooAccountProxy;
    ThrowProxy private operatorAccountProxy;
    address private fooAccount;
    address private operatorAccount;
    uint256 private initialCreditBalance = 100;
    uint256 private transferringAmount = 30;

    function beforeEach() external {
        credit = new EER2B();
        fooAccountProxy = new PayableThrowProxy(address(credit));
        fooAccount = address(fooAccountProxy);
        operatorAccountProxy = new ThrowProxy(address(credit));
        operatorAccount = address(operatorAccountProxy);
        prepareOperator(true);
    }

    function prepareNonFungible() internal returns (uint256) {
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;

        credit.mintNonFungible(nonFungibleCreditType, tos);
        return nonFungibleCreditType;
    }

    function prepareOperator(bool approved) internal {
        EER2B(fooAccount).setApprovalForAll(operatorAccount, approved);
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testTransferNonFungibleCreditToAccount() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 1;
        address barAccount = address(1);

        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditType),
            1,
            "balance of non fungible credit type of the foo account should be 1"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditType),
            0,
            "balance of non fungible credit type of the bar account should be 0"
        );
        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditID),
            1,
            "foo account should own non-fungible credit"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditID),
            0,
            "bar account should not own non-fungible credit"
        );

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            nonFungibleCreditID,
            1,
            bytes("")
        );
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditType),
            0,
            "balance of non fungible credit type of the foo account should be 0"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditType),
            1,
            "balance of non fungible credit type of the bar account should be 1"
        );
        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditID),
            0,
            "foo account should not own non-fungible credit"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditID),
            1,
            "bar account should own non-fungible credit"
        );
    }

    function testAuthorizedOperatorTransferNonFungibleCreditToTokenReceivedContract() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 1;
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);

        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditType),
            1,
            "balance of non fungible credit type of the foo account should be 1"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditType),
            0,
            "balance of non fungible credit type of the bar account should be 0"
        );
        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditID),
            1,
            "foo account should own non-fungible credit"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditID),
            0,
            "bar account should not own non-fungible credit"
        );

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            nonFungibleCreditID,
            1,
            bytes("")
        );
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditType),
            0,
            "balance of non fungible credit type of the foo account should be 0"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditType),
            1,
            "balance of non fungible credit type of the bar account should be 1"
        );
        Assert.equal(
            credit.balanceOf(fooAccount, nonFungibleCreditID),
            0,
            "foo account should not own non-fungible credit"
        );
        Assert.equal(
            credit.balanceOf(barAccount, nonFungibleCreditID),
            1,
            "bar account should own non-fungible credit"
        );
    }
}
