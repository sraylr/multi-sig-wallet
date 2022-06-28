pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

contract MultiSigWallet {
  
  event Deposit(address indexed signer, uint256 amount);
  event Submit(uint256 indexed txId);
  event Approve(address indexed owner, uint256 indexed txId);
  event Revoke(address indexed owner, uint256 indexed txId);
  event Execute(uint256 indexed txId);

  address[] public owners;
  mapping(address => bool) public isOwner;
  uint256 public requiredApprovals;

  struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
  }

  Transaction[] public transactions;

  mapping(uint256 => mapping(address => bool)) public approved;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "onlyOwner(): sender is not owner");
    _;
  }

  modifier txExists(uint256 _txId) {
    require(_txId < transactions.length, "txExists(): tx does not exist");
    _;
  }

  modifier notApproved(uint256 _txId) {
    require(!approved[_txId][msg.sender], "notApproved(): tx already approved");
    _;
  }

  modifier notExecuted(uint256 _txId) {
    require(!transactions[_txId].executed, "notExecuted(): tx already executed");
    _;
  }

  constructor(address[] memory _owners, uint256 _requiredApprovals) {
    require(_owners.length > 0, "constructor(): owners required");
    require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "constructor(): invalid number of required approvals");

    for (uint256 i; i < _owners.length; i++) {

      address owner = _owners[i];

      require(owner != address(0), "constructor(): invalid owner");
      require(!isOwner[owner], "constructor(): owner is not unique");

      isOwner[owner] = true;
      owners.push(owner);
      }

      requiredApprovals = _requiredApprovals;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
    transactions.push(Transaction({
      to: _to,
      value: _value,
      data: _data,
      executed: false
    }));

    emit Submit(transactions.length - 1);
  }

  function approve(uint256 _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
    approved[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
    require(approved[_txId][msg.sender], "revoke(): tx not approved");
    approved[_txId][msg.sender] = false;
    emit Revoke(msg.sender, _txId);
  }

  function execute(uint256 _txId) external txExists(_txId) notExecuted(_txId) {
    require(_getApprovalCount(_txId) >= requiredApprovals, "execute(): not enough approvals");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "execute(): tx failed");

    emit Execute(_txId);
  }

  function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
    for (uint256 i; i < owners.length; i++) {
      if (approved[_txId][owners[i]]) {
        count += 1;
      }
    }
  }
}