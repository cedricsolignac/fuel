//on declare le contrat
// langae sway copy de Rust
contract;

//les standards utilisable
use std::{
    auth::{
        AuthError,
        msg_sender,
    },
    call_frames::{
        msg_asset_id,
    },
    context::{
        msg_amount,
    },
    revert::require,
    token::transfer_to_address
};
//on stock
storage {
    deposits: StorageMap<(Address, ContractId), u64> = StorageMap {},
}

enum Error {
    InsufficientBalance: (),
}
abi MoneyBox {
  // il est nécessaire de fournir ce décorateur qui montre quel type de
   // autorisation ecriture lecture des fonctions
    #[storage(write, read)]
    fn deposit();

    #[storage(write, read)]
    fn witdraw(asset_id: ContractId, amount: u64);

    #[storage(read)]
    fn balance(address: Address, asset_id: ContractId) -> u64;
}

fn get_msg_sender_address_or_panic() -> Address {
    let sender: Result<Identity, AuthError> = msg_sender();
    if let Identity::Address(address) = sender.unwrap() {
        address
    } else {
        revert(0);
    }
}

//la fonction retourne la valeur du wallet
#[storage(read)]
fn balance_internal(address: Address, asset_id: ContractId) -> u64 {
    let key = (address, asset_id);
    storage.deposits.get(key)
}

impl MoneyBox for Contract {
    #[storage(write, read)]
    fn deposit() {
//montant du token rattaché au paiement
        let amount = msg_amount();
//ID d'actif du jeton attaché au paiement
        let asset_id = msg_asset_id();
        let address = get_msg_sender_address_or_panic();

        let key = (address, asset_id);
//montant total qui sera augmenté s'il y a déjà un dépôt d'utilisateur
        let amount = amount + storage.deposits.get(key);
        storage.deposits.insert(key, amount);
    }

//fonction qui renvoie le solde des utilisateurs et peut être appelée
    #[storage(read)]
    fn balance(address: Address, asset_id: ContractId) -> u64 {
//à l'intérieur, il utilise notre fonction util qui est déclarée ci-dessus
        balance_internal(address, asset_id)
    }

//fonction pour retirer le token
    #[storage(write, read)]
    fn withdraw(asset_id: ContractId, amount: u64) {
//adresse de l'utilisateur 
        let address = get_msg_sender_address_or_panic();
//balance de l'utilisateur avant le retrait
        let balance = balance_internal(address, asset_id);
//vérifier que le montant requis est inférieur ou égal au solde de l'utilisateur sinon
// il lancera une erreur
        require(balance >= amount, Error::InsufficientBalance);

//fonction qui renvoie de l'argent à l'utilisateur si l'enregistrement est réussi
        transfer_to_address(amount, asset_id, address);

        let amount_after = balance - amount;
        let key = (address, asset_id);
        if amount_after > 0 {
            storage.deposits.insert(key, amount_after);
        } else{
            storage.deposits.insert(key, 0);
        }
    }
}