//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;


import {ERC721,IERC721Errors} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/*
    @dev error interface for DelayPayment contract.
*/
interface PaymentErrors {

    //Payments should not be overpayed
    error OverpaymentError(uint256 amount, uint256 owed);

    //Payments that can't yet be reclaimed
    error UnmaturedPayment(uint256 dueTime);

    //Payments that can be claimed but remain unpayed
    error Unpayed(uint256 paymentId);

    //Payment that has already been payed
    error Payed(uint256 paymentId);

    //A slash debtor can't generate new Payments until it pays it's own debts
    error SlashedDebtor(address _debtor);

    //Someone that hasn't the right to claim a payment can't do certain actions
    error NotBeneficiary(address caller, uint256 paymentId);

    error NotYourDebt(address caller,uint256 paymentId);

    error NotInTime();

}

contract DelayPayment is ERC721 {

    struct Payment {
        address beneficiary;
        uint256 amount;
        uint256 payed;
        uint48 dueTime;
    }

    event NewPayment(address _beneficiary, address _debtor, uint256 _id);
    event SlashedPayer(address _payer, uint256 _id);
    event SplitPayment(uint256 _paymentId, uint256 _splittedId, address _debtor);

    mapping(uint256 => Payment) public payments;
    mapping(address => uint256 slashedPayments) public slashed;

    //Used to generate unique IDs for the different payments
    uint256 private _counter;

    constructor() ERC721("DelayedPayments", "DPA") payable {
        _counter = 0;
    }

    /*
        @dev checks that _debtor has no unpayed debts.
    */
    modifier unslashed(address _debtor) {
        if (slashed[_debtor] > 0) {
            revert PaymentErrors.SlashedDebtor(_debtor);
        }
        _;
    }

    /*
        @dev creates a payment and emits a NewPayment event
    */
    function _createPayment(address _debtor, uint256 _dueTime, uint256 _amount, address _beneficiary) private unslashed(_debtor) returns(uint256 id) {
        if(block.timestamp>_dueTime){
            revert PaymentErrors.NotInTime();
        }
        uint256 _id = uint256(keccak256(abi.encodePacked(msg.sender, _counter)));
        payments[_id] = Payment(_beneficiary, _amount, _dueTime, 0);
        _counter += 1;
        emit NewPayment(_beneficiary, msg.sender, _id);
        _safeMint(msg.sender, _id);
        return _id;
    }

    /*
        @dev creates a new payment by minting a new ERC721 token

        - Arguments:
            - _dueTime represents the timestamp after which the payment can be reclaimed
            - _amount represents the total Wei that should be payed by the creator of the payment
            - _beneficiary represents the address that will be able to reclaim the payment
        - Requirements:
            - The address creating the payment must have no slashed payments
    */
    function createPayment(uint256 _dueTime, uint256 _amount, address _beneficiary) public returns(uint256 id) {
        return _createPayment(msg.sender, _dueTime, _amount, _beneficiary);
    }

    /*
        @dev reduces the amount owed to Payment[_paymentId] and creates a new
        payment with the given amount.

        - Arguments
            - _paymentId is the Id of the payment to be splited
            - _amount is the amount to be used to create a new payment
    */
    function _splitPayment(uint256 _paymentId, uint256 _amount) internal {
        address _owner = ownerOf(_paymentId);
        Payment storage _original = payments[_paymentId];
        if (msg.sender != _original.beneficiary) {
            revert PaymentErrors.NotBeneficiary(msg.sender, _paymentId);
        }
        if (_amount > _original.amount) {
            revert PaymentErrors.OverpaymentError(_amount, _original.amount);
        }
        _createPayment(_owner, _original.dueTime, _amount, _original.beneficiary);
        _original.amount = _original.amount - _amount;
    }


    /*
        @dev pays one payment with another

        - Arguments:
            - _withId is the Id of the payment to be used to cancel _paymentId
            - _paymentId is the ID of the payment to be payed

        - Requirements:
            - Payment[_withId].dueTime <= Payment[_paymentId].dueTime
            - Payment[_withId].amount >= Payment[_paymentId].amount
            - msg.sender must be the beneficiary of Payment[_withId]
            - msg.sender must be the owner of Payment[_paymentId]
    */
    function payWithPayment(uint256 _withId, uint256 _paymentId) public {
        ownerOf(_paymentId);
        Payment storage _payment = payments[_paymentId];
        _splitPayment(_withId, _payment.amount);
        _burn(_paymentId);
        if (slashed[msg.sender] > 0) {
            slashed[msg.sender] -= 1;
        }
    }

    /*
        @dev pays an amount to a given payment

        - Arguments
            - _paymentId is the payment into which the funds will be poured
            - msg.value will be used as the payed amount

        - Requirements
            - amount payed must be <= than Payment.amount-Payment.payed
            - _paymentId must exist

    */
    function pay(uint256 _paymentId) public payable {
        address _owner = ownerOf(_paymentId);
        Payment storage payment = payments[_paymentId];
        if(msg.sender != _owner){
            revert PaymentErrors.NotYourDebt(msg.sender, _paymentId);
        }

        if (msg.value > (payment.amount - payment.payed)) {
            revert PaymentErrors.OverpaymentError(msg.value, payment.amount - payment.payed);
        }

        payment.payed = payment.payed + msg.value;
    }


    /*
        @dev reclaims a payment in full

        - Arguments
            - _paymentId is the payment to be reclaimed

        - Requirements
            - Payments[_paymentId] should have been payed
            - Payment.beneficiary must be equal msg.sender
            - _amount must be <= to Payment.payed
    */
    function claim(uint256 _paymentId) public {
        address _owner = ownerOf(_paymentId);
        Payment memory payment = payments[_paymentId];
        if (payment.beneficiary != msg.sender) {
            revert PaymentErrors.NotBeneficiary(msg.sender, _paymentId);
        }
        if (payment.dueTime > block.timestamp) {
            revert PaymentErrors.UnmaturedPayment(payment.dueTime);
        }
        if (payment.payed < payment.amount) {
            revert PaymentErrors.Unpayed(_paymentId);
        }
        _burn(_paymentId);
        (bool success, ) = msg.sender.call{value: payment.amount}("");
        require(success);
        if (slashed[_owner] > 0) {
            slashed[_owner] -= 1;
        }
    }

    /*
        @dev slashes the owner of a payment that was due but remained unpaid

        - Requirements
            - _paymentId must be past due and unpayed
    */
    function slashPayer(uint256 _paymentId) public {
        address _owner = ownerOf(_paymentId);
        Payment memory _payment = payments[_paymentId];
        if (_payment.payed == _payment.amount) {
            revert PaymentErrors.Payed(_paymentId);
        }
        if (_payment.dueTime >= block.timestamp) {
            revert PaymentErrors.UnmaturedPayment(_payment.dueTime);
        }
        slashed[_owner] += 1;
        emit SlashedPayer(_owner, _paymentId);
    }

    /*
        @dev override of ERC721 _update method. Calls the original _update for creating
        and modifying payments when it is not a transfer.
        Transfering a payment means transfering the rights to claim it later.
    */
    function _update(address _to, uint256 _paymentId, address _auth) internal override returns(address addr) {
        address owner = _ownerOf(_paymentId);
        if (owner == address(0)) {
            return super._update(_to, _paymentId, _auth);
        }
        if (_to != address(0)) {
            //Modification of beneficiary
            Payment storage payment = payments[_paymentId];
            if (msg.sender != payment.beneficiary) {
                revert PaymentErrors.NotBeneficiary(msg.sender, _paymentId);
            }
            payments[_paymentId].beneficiary = _to;
            return _to;
        }
        return super._update(_to, _paymentId, _auth);
    }
}
