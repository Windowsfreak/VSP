package test;

import bank_access.Account;
import bank_access.AccountImplBase;
import bank_access.OverdraftException;
import mware_lib.ObjectBroker;

public class NameServiceTester {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		ObjectBroker ob = ObjectBroker.init("localhost", 10000);
		mware_lib.NameService ns = ob.getNameService();
		AccountImplBase account = new Account();
		ns.rebind(account, "account");
		Object objRef = ns.resolve("account");
		Object[] objRefModifier = (Object[]) objRef;
		objRefModifier[0] = "localhost";
		AccountImplBase account2 = Account.narrowCast(objRef);
		System.out.println("Jippie!");
		System.out.println(((Object[]) objRef)[0]);
		System.out.println(((Object[]) objRef)[1]);
		System.out.println(((Object[]) objRef)[2]);
		System.out.println(account2.getBalance());
		try {
			account2.transfer(200);
		} catch (OverdraftException e) {
			e.printStackTrace();
		}
		System.out.println(account2.getBalance());
		try {
			account2.transfer(-400);
		} catch (OverdraftException e) {
			e.printStackTrace();
		}
		ob.shutdown();
	}

}
