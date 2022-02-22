import {
    Approval as ApprovalEvent,
    Transfer as TransferEvent,
    SnowGlobe
  } from "../../generated/SnowGlobe/SnowGlobe"
  import * as store from '../store/store'
  import {
    Address,bigInt,BigInt
  } from "@graphprotocol/graph-ts";

  const zeroAddress = Address.fromString("0x0000000000000000000000000000000000000000")

  export function handleApproval(event: ApprovalEvent): void {
    store.createApproval(event);
  }
  
  export function handleTransfer(event: TransferEvent): void {
    // minting here is zero
    if (event.params.from == zeroAddress) { 
      handleDeposit(event);
    } else if (event.params.to == zeroAddress)  { 
      handleWithdraw(event);
    } else {
      //we only want to register transfers between valid addresses
      store.createTransfer(event);
    }
  }
  
  function handleDeposit(event:TransferEvent): void { 
    const contract = SnowGlobe.bind(event.address);
    let globeRatio:BigInt
    
    if(contract.balance() > bigInt.fromString("0")) {
      globeRatio = contract.getRatio();
    } else {
      globeRatio = BigInt.fromString("1000000000000000000");
    }

    const lpValue = event.params.value.times(globeRatio).div(BigInt.fromString("1000000000000000000"));
    store.createDeposit(event, lpValue, globeRatio);
  }

  function handleWithdraw(event:TransferEvent): void { 
    const contract = SnowGlobe.bind(event.address);
    let globeRatio:BigInt

    if(contract.balance() > bigInt.fromString("0")) {
      globeRatio = contract.getRatio();
    } else {
      globeRatio = BigInt.fromString("1000000000000000000");
    }

    const lpValue = event.params.value.times(globeRatio).div(BigInt.fromString("1000000000000000000"));
    store.createWithdraw(event, lpValue, globeRatio);
  }
  