package cash_access;

import mware_lib.IImplBase;


public abstract class TransactionImplBase implements IImplBase {
	public abstract void deposit(String accountId, double amount)
			throws InvalidParamException;

	public abstract void withdraw(String accountId, double amount)
			throws InvalidParamException, OverdraftException;

	public abstract double getBalance(String accountId)
			throws InvalidParamException;

	public static TransactionImplBase narrowCast(Object o) {
		Object[] objRef = (Object[]) o;
		return new TransactionStub((String) objRef[0], (int) objRef[1], objRef[2]);
	}

	public TransactionSkeleton getSkeleton() {
		return new TransactionSkeleton(this);
	}
}