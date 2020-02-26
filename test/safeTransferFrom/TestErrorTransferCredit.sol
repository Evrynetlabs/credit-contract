pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../utils/ThrowProxy.sol";
import "../utils/PayableThrowProxy.sol";
import "../../contracts/EER2B.sol";


contract TestErrorTransferCredit {
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

    function prepareNonFungible() internal returns (uint256) {
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;

        credit.mintNonFungible(nonFungibleCreditType, tos);
        return nonFungibleCreditType;
    }

    function prepareOperator(bool approved) internal {
        EER2B(fooAccount).setApprovalForAll(operatorAccount, approved);
        (bool success, ) = fooAccountProxy.execute();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testErrorTransferCreditToZeroAddress() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(0);
        prepareOperator(true);

        EER2B(fooAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error owner transfers to zero address");

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            fungibleCreditID,
            1,
            bytes("")
        );
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error operator transfers to zero address");
    }

    function testErrorUnauthorizedOperator() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        prepareOperator(false);

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            fungibleCreditID,
            transferringAmount,
            bytes("")
        );
        (bool success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error no transfer permission");
    }

    function testErrorTransferNonFungibleCreditWithoutOwnership() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 2;
        address barAccount = address(1);
        prepareOperator(true);

        EER2B(fooAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            nonFungibleCreditID,
            1,
            bytes("")
        );
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error transfer without ownership");

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            nonFungibleCreditID,
            1,
            bytes("")
        );
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error transfer without ownership via operator");
    }

    function testErrorTransferCreditToNotSupportedContract() external {
        uint256 fungibleCreditID = prepareFungible();
        address barContract = address(new ThrowProxy(address(1)));
        prepareOperator(true);

        EER2B(fooAccount).safeTransferFrom(fooAccount, barContract, fungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error owner transfers to not supported contract");

        EER2B(operatorAccount).safeTransferFrom(
            fooAccount,
            barContract,
            fungibleCreditID,
            1,
            bytes("")
        );
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error operator transfers to not supported contract");
    }

    function testErrorTransferCreditInsufficientAmount() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        uint256 overTransferringAmount = 120;

        EER2A(fooAccount).safeTransferFrom(
            fooAccount,
            barAccount,
            fungibleCreditID,
            overTransferringAmount,
            bytes("")
        );
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(
            success,
            "should throw error insufficient amount to transfer fungible credit"
        );
    }
}
