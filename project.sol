// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoBackedLoans {
    struct Loan {
        address borrower;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 repaymentAmount;
        uint256 dueDate;
        bool isRepaid;
    }

    mapping(address => Loan[]) public loans;
    uint256 public interestRate = 5; // 5% interest
    uint256 public duration = 30 days; // Loan duration
    address public owner;

    event LoanCreated(address indexed borrower, uint256 loanAmount, uint256 collateralAmount, uint256 dueDate);
    event LoanRepaid(address indexed borrower, uint256 loanAmount);
    event CollateralWithdrawn(address indexed borrower, uint256 collateralAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createLoan(uint256 loanAmount) external payable {
        require(msg.value > 0, "Collateral is required");
        require(loanAmount > 0, "Loan amount must be greater than zero");
        
        uint256 collateralAmount = msg.value;
        uint256 repaymentAmount = loanAmount + (loanAmount * interestRate / 100);
        uint256 dueDate = block.timestamp + duration;

        loans[msg.sender].push(Loan({
            borrower: msg.sender,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            repaymentAmount: repaymentAmount,
            dueDate: dueDate,
            isRepaid: false
        }));

        payable(msg.sender).transfer(loanAmount);
        emit LoanCreated(msg.sender, loanAmount, collateralAmount, dueDate);
    }

    function repayLoan(uint256 loanIndex) external payable {
        Loan storage loan = loans[msg.sender][loanIndex];
        require(!loan.isRepaid, "Loan is already repaid");
        require(msg.value == loan.repaymentAmount, "Incorrect repayment amount");
        require(block.timestamp <= loan.dueDate, "Loan repayment is overdue");

        loan.isRepaid = true;
        emit LoanRepaid(msg.sender, loan.loanAmount);
    }

    function withdrawCollateral(uint256 loanIndex) external {
        Loan storage loan = loans[msg.sender][loanIndex];
        require(loan.isRepaid, "Loan must be repaid before withdrawing collateral");
        
        uint256 collateralAmount = loan.collateralAmount;
        loan.collateralAmount = 0;

        payable(msg.sender).transfer(collateralAmount);
        emit CollateralWithdrawn(msg.sender, collateralAmount);
    }

    function updateInterestRate(uint256 newRate) external onlyOwner {
        interestRate = newRate;
    }

    function updateDuration(uint256 newDuration) external onlyOwner {
        duration = newDuration;
    }

    receive() external payable {}
}
