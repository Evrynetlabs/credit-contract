pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";

contract TestValidParameters {
    EER2B private credit;
    uint256[] private ids;
    uint256[] private values;
    address[] private tos;
    address[] private senders;
    PayableThrowProxy private creditOwnerProxy;
    PayableThrowProxy private receiverProxy;
    PayableThrowProxy private senderProxy;
    EER2B private creditOwner;
    EER2B private receiverContract;
    EER2B private sender;
    bool private result;
    string private uri = "bar";
    bytes private data = "foo";
    address private receiverAccountAddr = address(1);
    uint256 private defaultQuantity = 100;
    uint256 private defaultValue = 1;
    uint256 private expectedFungibleQuantityLeft = defaultQuantity -
        defaultValue;

    // ********************************************* Internal Function *********************************************

    // ************** set up full batch transaction parameters *****

    function createFungibleCredit() internal returns (uint256 _id) {
        _id = credit.create(uri, false);
    }

    function createNonFungibleCredit() internal returns (uint256 _type) {
        _type = credit.create(uri, true);
    }

    function setupTest() public {
        credit = new EER2B();
        result = false;
        tos = new address[](0);
        senders = new address[](0);
        ids = new uint256[](0);
        values = new uint256[](0);
        creditOwnerProxy = new PayableThrowProxy(address(credit));
        creditOwner = EER2B(address(creditOwnerProxy));
        receiverProxy = new PayableThrowProxy(address(credit));
        receiverContract = EER2B(address(receiverProxy));
        senderProxy = new PayableThrowProxy(address(credit));
        sender = EER2B(address(senderProxy));
        creditOwner.setApprovalForAll(address(sender), true);
        (result, ) = creditOwnerProxy.execute();
        Assert.isTrue(
            result,
            "balance owner should successfully approve receiverContract as an operator"
        );
        Assert.isTrue(
            credit.isApprovedForAll(address(creditOwner), address(sender)),
            "sender should be an operator of balance owner"
        );
    }

    function fillUpMintNonFungible() internal {
        address[] memory _senders = new address[](1);
        _senders[0] = senders[senders.length - 1];

        credit.mintNonFungible(
            credit.getNonFungibleBaseType(ids[ids.length - 1]),
            _senders
        );
    }

    function fillUpMintFungible() internal {
        uint256[] memory _quantities = new uint256[](1);
        address[] memory _senders = new address[](1);
        _quantities[0] = defaultQuantity;
        _senders[0] = senders[senders.length - 1];
        credit.mintFungible(ids[ids.length - 1], _senders, _quantities);
    }

    function fillUpCreateNonFungible() internal {
        uint256 _id = createNonFungibleCredit() + 1;
        ids.push(_id);
    }

    function fillUpCreateFungible() internal {
        uint256 _id = createFungibleCredit();
        ids.push(_id);
    }

    function fillUpToContract() internal {
        tos.push(address(receiverContract));
    }

    function fillUpToEOA() internal {
        tos.push(receiverAccountAddr);
    }

    function fillUpSenderFrom() internal {
        senders.push(address(sender));
    }

    function fillUpSenderOperator() internal {
        senders.push(address(creditOwner));
    }

    function fillUpValue() internal {
        values.push(defaultValue);
    }

    // **************** sender as from *****************

    /** 
        sender from -> send non fungible -> to address
     */
    function fillUpSenderFromSendNonfungibleToAddress() internal {
        fillUpValue();
        fillUpSenderFrom();
        fillUpToEOA();
        fillUpCreateNonFungible();
        fillUpMintNonFungible();
    }

    /** 
        sender from -> send non fungible -> to contract
     */
    function fillUpSenderFromSendNonfungibleToContract() internal {
        fillUpValue();
        fillUpSenderFrom();
        fillUpToContract();
        fillUpCreateNonFungible();
        fillUpMintNonFungible();
    }

    /** 
        sender from -> send fungible -> to address
     */
    function fillUpSenderFromSendFungibleToAddress() internal {
        fillUpValue();
        fillUpSenderFrom();
        fillUpToEOA();
        fillUpCreateFungible();
        fillUpMintFungible();
    }

    /** 
        sender from -> send fungible -> to contract
     */
    function fillUpSenderFromSendFungibleToContract() internal {
        fillUpValue();
        fillUpSenderFrom();
        fillUpToContract();
        fillUpCreateFungible();
        fillUpMintFungible();
    }

    // **************** sender as operator *****************

    /** 
        sender operator -> send non fungible -> to address
     */
    function fillUpSenderOperatorSendNonfungibleToAddress() internal {
        fillUpValue();
        fillUpSenderOperator();
        fillUpToEOA();
        fillUpCreateNonFungible();
        fillUpMintNonFungible();
    }

    /** 
        sender operator -> send non fungible -> to contract
     */
    function fillUpSenderOperatorSendNonfungibleToContract() internal {
        fillUpValue();
        fillUpSenderOperator();
        fillUpToContract();
        fillUpCreateNonFungible();
        fillUpMintNonFungible();
    }

    /** 
        sender operator -> send fungible -> to address
     */
    function fillUpSenderOperatorSendFungibleToAddress() internal {
        fillUpValue();
        fillUpSenderOperator();
        fillUpToEOA();
        fillUpCreateFungible();
        fillUpMintFungible();
    }

    /** 
        sender operator -> send fungible -> to contract
     */
    function fillUpSenderOperatorSendFungibleToContract() internal {
        fillUpValue();
        fillUpSenderOperator();
        fillUpToContract();
        fillUpCreateFungible();
        fillUpMintFungible();
    }

    function executeSafeFullBatchTransferFrom()
        internal
        returns (bool _result)
    {
        sender.safeFullBatchTransferFrom(senders, tos, ids, values, data);
        (_result, ) = senderProxy.execute();
    }

    // ********************************************* External Function *********************************************

    function beforeEach() external {
        setupTest();
    }

    function testFullBatchTransfer() external {
        fillUpSenderFromSendNonfungibleToAddress();
        fillUpSenderFromSendNonfungibleToContract();
        fillUpSenderFromSendFungibleToAddress();
        fillUpSenderFromSendFungibleToContract();
        fillUpSenderOperatorSendNonfungibleToAddress();
        fillUpSenderOperatorSendNonfungibleToContract();
        fillUpSenderOperatorSendFungibleToAddress();
        fillUpSenderOperatorSendFungibleToContract();
        result = executeSafeFullBatchTransferFrom();
        Assert.isTrue(
            result,
            "should pass since parameters with 8 cases are valid"
        );
        /**
            balance assertion of sender as from and sender as operator
         */
        Assert.equal(
            credit.balanceOf(address(sender), ids[0]),
            0,
            "balance of non fungible credit id[0] of the sender should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(sender), ids[1]),
            0,
            "balance of non fungible credit id[1] of the sender should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(sender), ids[2]),
            expectedFungibleQuantityLeft,
            "balance of fungible credit id[2] of the sender should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(sender), ids[3]),
            expectedFungibleQuantityLeft,
            "balance of fungible credit id[3] of the sender should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(creditOwner), ids[4]),
            0,
            "balance of non fungible credit id[4] of the sender (with approval from balance owner) should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(creditOwner), ids[5]),
            0,
            "balance of non fungible credit id[5] of the sender (with approval from balance owner) should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(creditOwner), ids[6]),
            expectedFungibleQuantityLeft,
            "balance of fungible credit id[6] of the sender (with approval from balance owner) should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(creditOwner), ids[7]),
            expectedFungibleQuantityLeft,
            "balance of fungible credit id[7] of the sender (with approval from balance owner) should be 0"
        );
        /**
            balance assertion of receiver as contract and account address
        */
        Assert.equal(
            credit.balanceOf(address(receiverAccountAddr), ids[0]),
            defaultValue,
            "balance of the receiver of id[0] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverContract), ids[1]),
            defaultValue,
            "balance of the receiver of id[1] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverAccountAddr), ids[2]),
            defaultValue,
            "balance of the receiver of id[2] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverContract), ids[3]),
            defaultValue,
            "balance of the receiver of id[3] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverAccountAddr), ids[4]),
            defaultValue,
            "balance of the receiver of id[4] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverContract), ids[5]),
            defaultValue,
            "balance of the receiver of id[5] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverAccountAddr), ids[6]),
            defaultValue,
            "balance of the receiver of id[6] should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(receiverContract), ids[7]),
            defaultValue,
            "balance of the receiver of id[7] should be 1"
        );
    }
}
