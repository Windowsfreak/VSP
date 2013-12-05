package bank_access;

import mware_lib.IImplBase;

public abstract class AccountImplBase implements IImplBase {
	public abstract void transfer(double amount) throws OverdraftException;

	public abstract double getBalance();

	public static AccountImplBase narrowCast(Object o) {
		Object[] objRef = (Object[]) o;
		return new AccountStub((String) objRef[0], (int) objRef[1], objRef[2]);
	}

	public AccountSkeleton getSkeleton() {
		return new AccountSkeleton(this);
	}
}