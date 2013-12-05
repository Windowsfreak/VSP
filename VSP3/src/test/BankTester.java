package test;

import bank.Bank;
import bank_access.Account;
import bank_access.AccountImplBase;
import bank_access.OverdraftException;
import mware_lib.ObjectBroker;

public class BankTester {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		Bank.main(new String[] {"localhost", "10000", "bank1"});
	}

}
