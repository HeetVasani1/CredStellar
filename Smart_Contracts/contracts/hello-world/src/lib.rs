#![no_std]
use soroban_sdk::{contract, contractimpl, Env, Address, Symbol};

#[contract]
pub struct LendingContract;

#[contractimpl]
impl LendingContract {

    // 🔹 Deposit FD (lock funds)
    pub fn deposit(env: Env, user: Address, amount: i128) {
        user.require_auth();

        let fd_key = (Symbol::short("FD"), user.clone());
        let current: i128 = env.storage().instance().get(&fd_key).unwrap_or(0);

        env.storage().instance().set(&fd_key, &(current + amount));
    }

    // 🔹 Mint credit based on FD
    pub fn mint_credit(env: Env, user: Address, amount: i128) {
        user.require_auth();

        let fd_key = (Symbol::short("FD"), user.clone());
        let fd_balance: i128 = env.storage().instance().get(&fd_key).unwrap_or(0);

        if fd_balance < amount {
            panic!("Not enough FD collateral");
        }

        let credit_key = (Symbol::short("CR"), user.clone());
        let current: i128 = env.storage().instance().get(&credit_key).unwrap_or(0);

        env.storage().instance().set(&credit_key, &(current + amount));
    }

    // 🔹 Repay (burn credit)
    pub fn repay(env: Env, user: Address, amount: i128) {
        user.require_auth();

        let credit_key = (Symbol::short("CR"), user.clone());
        let current: i128 = env.storage().instance().get(&credit_key).unwrap_or(0);

        if current < amount {
            panic!("Not enough credit");
        }

        env.storage().instance().set(&credit_key, &(current - amount));
    }

    // 🔹 Withdraw FD (only if no debt)
    pub fn withdraw(env: Env, user: Address, amount: i128) {
        user.require_auth();

        let fd_key = (Symbol::short("FD"), user.clone());
        let credit_key = (Symbol::short("CR"), user.clone());

        let fd_balance: i128 = env.storage().instance().get(&fd_key).unwrap_or(0);
        let credit_balance: i128 = env.storage().instance().get(&credit_key).unwrap_or(0);

        if credit_balance > 0 {
            panic!("Outstanding debt exists");
        }

        if fd_balance < amount {
            panic!("Insufficient FD balance");
        }

        env.storage().instance().set(&fd_key, &(fd_balance - amount));
    }

    // 🔹 Liquidation (if credit > FD)
    pub fn liquidate(env: Env, user: Address) {
        let fd_key = (Symbol::short("FD"), user.clone());
        let credit_key = (Symbol::short("CR"), user.clone());

        let fd_balance: i128 = env.storage().instance().get(&fd_key).unwrap_or(0);
        let credit_balance: i128 = env.storage().instance().get(&credit_key).unwrap_or(0);

        if credit_balance > fd_balance {
            // wipe collateral
            env.storage().instance().set(&fd_key, &0);
        }
    }

    // 🔍 View functions
    pub fn get_fd(env: Env, user: Address) -> i128 {
        let key = (Symbol::short("FD"), user);
        env.storage().instance().get(&key).unwrap_or(0)
    }

    pub fn get_credit(env: Env, user: Address) -> i128 {
        let key = (Symbol::short("CR"), user);
        env.storage().instance().get(&key).unwrap_or(0)
    }
}