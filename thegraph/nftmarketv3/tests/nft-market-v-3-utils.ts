import { newMockEvent } from "matchstick-as"
import { ethereum, Bytes, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Cancel,
  EIP712DomainChanged,
  List,
  OwnershipTransferred,
  SetFeeTo,
  SetWhiteListSigner,
  Sold
} from "../generated/NFTMarketV3/NFTMarketV3"

export function createCancelEvent(orderId: Bytes): Cancel {
  let cancelEvent = changetype<Cancel>(newMockEvent())

  cancelEvent.parameters = new Array()

  cancelEvent.parameters.push(
    new ethereum.EventParam("orderId", ethereum.Value.fromFixedBytes(orderId))
  )

  return cancelEvent
}

export function createEIP712DomainChangedEvent(): EIP712DomainChanged {
  let eip712DomainChangedEvent = changetype<EIP712DomainChanged>(newMockEvent())

  eip712DomainChangedEvent.parameters = new Array()

  return eip712DomainChangedEvent
}

export function createListEvent(
  nft: Address,
  tokenId: BigInt,
  orderId: Bytes,
  seller: Address,
  payToken: Address,
  price: BigInt,
  deadline: BigInt
): List {
  let listEvent = changetype<List>(newMockEvent())

  listEvent.parameters = new Array()

  listEvent.parameters.push(
    new ethereum.EventParam("nft", ethereum.Value.fromAddress(nft))
  )
  listEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  listEvent.parameters.push(
    new ethereum.EventParam("orderId", ethereum.Value.fromFixedBytes(orderId))
  )
  listEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  listEvent.parameters.push(
    new ethereum.EventParam("payToken", ethereum.Value.fromAddress(payToken))
  )
  listEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )
  listEvent.parameters.push(
    new ethereum.EventParam(
      "deadline",
      ethereum.Value.fromUnsignedBigInt(deadline)
    )
  )

  return listEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createSetFeeToEvent(to: Address): SetFeeTo {
  let setFeeToEvent = changetype<SetFeeTo>(newMockEvent())

  setFeeToEvent.parameters = new Array()

  setFeeToEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return setFeeToEvent
}

export function createSetWhiteListSignerEvent(
  signer: Address
): SetWhiteListSigner {
  let setWhiteListSignerEvent = changetype<SetWhiteListSigner>(newMockEvent())

  setWhiteListSignerEvent.parameters = new Array()

  setWhiteListSignerEvent.parameters.push(
    new ethereum.EventParam("signer", ethereum.Value.fromAddress(signer))
  )

  return setWhiteListSignerEvent
}

export function createSoldEvent(
  orderId: Bytes,
  buyer: Address,
  fee: BigInt
): Sold {
  let soldEvent = changetype<Sold>(newMockEvent())

  soldEvent.parameters = new Array()

  soldEvent.parameters.push(
    new ethereum.EventParam("orderId", ethereum.Value.fromFixedBytes(orderId))
  )
  soldEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  soldEvent.parameters.push(
    new ethereum.EventParam("fee", ethereum.Value.fromUnsignedBigInt(fee))
  )

  return soldEvent
}
