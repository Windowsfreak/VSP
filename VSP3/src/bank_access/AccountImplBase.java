package bank_access;

public abstract class AccountImplBase {
	public abstract void transfer(double amount) throws OverdraftException;

	public abstract double getBalance();

	public static AccountImplBase narrowCast(Object o) {
		Object[] objRef = (Object[]) o;
		return new AccountStub((String) objRef[0], (int) objRef[1], o);
	}

	public AccountSkeleton getSkeleton() {
		return new AccountSkeleton(this);
	}
}