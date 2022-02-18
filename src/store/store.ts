import { Transfer as TransferEvent, Approval as ApprovalEvent } from "../../generated/SnowGlobe/SnowGlobe";
import { Approval, Transfer, Withdraw, Deposit } from "../../generated/schema"
import { BigInt } from "@graphprotocol/graph-ts";

type Prefix = string;

export function createApproval(event: ApprovalEvent): void  {
  let entity = new Approval("ap"+ "-" + event.transaction.hash.toHex() + "-" + event.logIndex.toString());
  entity.owner = event.params.owner;
  entity.spender = event.params.spender;
  entity.value = event.params.value;
  entity.save();
}

export function createTransfer(event: TransferEvent): void  {
  let entity = new Transfer(createID("tf", event));
  entity.from = event.params.from;
  entity.to = event.params.to;
  entity.value = event.params.value;
  entity.snowglobeAddress = event.address.toString();
  entity.block = event.block.number;
  entity.save();
}

export function createDeposit(event: TransferEvent, lpValue: BigInt, ratio:BigInt): void {
  let entity = new Deposit(createID("dp", event));
  entity.owner = event.transaction.from;
  entity.lpValue = lpValue;
  entity.value = event.params.value;
  entity.hash = event.transaction.hash.toHex();
  entity.ratio = ratio;
  entity.snowglobeAddress = event.address.toString();
  entity.block = event.block.number;
  entity.save();
}

export function createWithdraw(event: TransferEvent, lpValue: BigInt, ratio:BigInt): void {
  let entity = new Withdraw(createID("wd", event));
  entity.owner = event.transaction.from;
  entity.lpValue = lpValue;
  entity.value = event.params.value;
  entity.hash = event.transaction.hash.toHex();
  entity.ratio = ratio;
  entity.snowglobeAddress = event.address.toString();
  entity.block = event.block.number;
  entity.save();
}

function createID(prefix: Prefix, event: TransferEvent): string {
  return prefix + "-" + event.transaction.hash.toHex() + "-" + event.logIndex.toString();
}
