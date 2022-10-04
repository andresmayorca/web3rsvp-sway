library event_platform;

use std::{
    identity::Identity,
    contract_id::ContractId,
};

abi eventPlatform {
    #[storage(read, write)]
    fn createEvent(maxCapacity: u64, deposit: u64, owner: Identity, eventName: str[10]) -> bool;

    #[storage(read, write)]
    fn rsvp(eventId: u64) -> bool;
}

pub struct Event {
    maxCapacity: u64, 
    deposit: u64, 
    owner: Identity,
    name: str[10],
    numOfRSVPs: u64
}
