// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract privateSale is Ownable, ReentrancyGuard{

    constructor(bool _isWhitelist, bool _depRestriction){
        isWhitelist = _isWhitelist;
        depRestriction = _depRestriction;
        index = 0;
    }

    struct depositItem {
        address senderAddress;
        uint depositAmount;
        bool whitelist; 
    }


    /*|| === GLOBAL VARIABLES === ||*/

    uint public index;
    uint public minDeposit;
    uint public maxDeposit;
    bool public isWhitelist; // Is whitelist in effect
    bool public depRestriction; // Is min/max deposit amount in effect
    address[] private whitelistAddr; // Array of whitelisted addresses


    /*|| === MAPPINGS === ||*/

    mapping (address => uint[]) private depositToAddress;
    mapping (uint => depositItem) private depositToIndex; 


    /*|| === EVENT EMMITER === ||*/

    event LogDeposit(address setFromAddress, uint256 amountDeposited);


    /*|| === GETTER FUNCTIONS === ||*/

    // Check if address is whitelisted
    function getIsWhitelisted(address _addr) public view returns(bool){
        for(uint i = 0; i < whitelistAddr.length; i++){
            if(whitelistAddr[i] == _addr){
                return true;
            }
        }
        return false;
    }

    // Get list of whitelisted addresses
    function getWhitelistAddresses() public view returns(address[] memory){
        return whitelistAddr;
    }

    // Get depositItem by index
    function getDepositInfoByIndex(uint _index) public view returns(depositItem memory){
        return depositToIndex[_index];
    }
    
    // Get depositItem index by address
    function getDepositIndexByAddress(address _addr) public view returns(uint[] memory){
        return depositToAddress[_addr];
    }

    // Get remaining deposit amount
    function getRemainingDeposit(address _addr) public view returns(int){
        if(depRestriction == true){
            uint[] memory deposits = getDepositIndexByAddress(_addr);
            uint total;
            for(uint i = 0; i < deposits.length; i++){
                total += getDepositInfoByIndex(deposits[i]).depositAmount;
            }
            if(total >= maxDeposit){
                return 0;
            }
            return int(maxDeposit - total);
        }
        return -1;
    }


    /*|| === PUBLIC FUNCTIONS === ||*/

    function depositETH() nonReentrant payable public{

        if(isWhitelist == true){
            require(getIsWhitelisted(msg.sender) == true, "Sender is not whitelisted");
        }
        if(depRestriction == true){
            require(msg.value >= minDeposit && msg.value <= maxDeposit, "Deposit amount not within boundaries");
            require(getRemainingDeposit(msg.sender) > 0, "Address has reached max deposit amount");
        }
        depositToIndex[index].senderAddress = msg.sender;
        depositToIndex[index].depositAmount = msg.value;
        depositToIndex[index].whitelist = isWhitelist;

        depositToAddress[msg.sender].push(index);

        index++;

        emit LogDeposit(msg.sender, msg.value);
    }


     /*|| === OWNER FUNCTIONS === ||*/

    // Add addresses to whitelist via array
    function addToWhitelist(address[] calldata _addr) onlyOwner public {
        for(uint i = 0; i < _addr.length; i++){
            if (getIsWhitelisted(_addr[i]) == false) {
                whitelistAddr.push(_addr[i]);
            }
        }
    }

    // Remove whitelisted address from the array
    function removeFromWhitelist(address  _addr) onlyOwner public{
        require(getIsWhitelisted(_addr) == true, "Address is not whitelisted");
        for(uint i = 0; i < whitelistAddr.length; i++){
            if(whitelistAddr[i] == _addr){
                whitelistAddr[i] = whitelistAddr[whitelistAddr.length - 1];
                whitelistAddr.pop();
            }
        }
    }

    // Set the min deposit
    function setMinDeposit(uint _minDeposit) onlyOwner public{
        require(_minDeposit <= maxDeposit, "Min deposit must be less than max deposit");
        minDeposit = _minDeposit;
    }

    // Set the max deposit 
    function setMaxDeposit(uint _maxDeposit) onlyOwner public{
        require(_maxDeposit >= minDeposit, "Max deposit must be greater than min deposit");
        maxDeposit = _maxDeposit;
    }

    // Set if whitelist mode
    function setWhitelist(bool _isWhitelist) onlyOwner public{
        isWhitelist = _isWhitelist;
    }

    // Set if deposits have restrictions
    function setDepositRestrictions(bool _depRestriction) onlyOwner public{
        depRestriction = _depRestriction;
    }

    // Claim bnb in contract
    function claimETH() external onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

}