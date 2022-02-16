import {
    Approval as ApprovalEvent,
    Transfer as TransferEvent,
    SnowGlobe
  } from "../../generated/SnowGlobe/SnowGlobe"
  import * as store from '../store/store'
  import {
    Address, bigInt,
  } from "@graphprotocol/graph-ts";

  const zeroAddress = Address.fromString("0x0000000000000000000000000000000000000000")

  export function handleApproval(event: ApprovalEvent): void {
    store.createApproval(event);
  }
  
  export function handleTransfer(event: TransferEvent): void {
    // create the transfer regardless of the event type
    store.createTransfer(event);
    // minting here is zero
    if (event.params.from == zeroAddress) { 
      handleDeposit(event);
    }
    if (event.params.to == zeroAddress)  { 
      handleWithdraw(event);
    }
  }
  
  function handleDeposit(event:TransferEvent): void { 
    const contract = SnowGlobe.bind(event.address);

    let globeRatio:bigInt;
    try {
      globeRatio = contract.getRatio();
    } catch (error) {
      //safemath error if globe is empty
      globeRatio = bigInt.fromString("1000000000000000000");
    }

    const lpValue = event.params.value.times(globeRatio).div(bigInt.fromString("1000000000000000000"));
    store.createDeposit(event, lpValue, globeRatio);
  }

  function handleWithdraw(event:TransferEvent): void { 
    const contract = SnowGlobe.bind(event.address);
    
    let globeRatio:bigInt;
    try {
      globeRatio = contract.getRatio();
    } catch (error) {
      //safemath error if globe is empty
      globeRatio = bigInt.fromString("1000000000000000000");
    }

    const lpValue = event.params.value.times(globeRatio).div(bigInt.fromString("1000000000000000000"));
    store.createWithdraw(event, lpValue, globeRatio);
  }
  