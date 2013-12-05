package bank_access;


public class Account extends AccountImplBase {
	public double balance;
	public Account() {
	}

	@Override
	public void transfer(double amount) throws OverdraftException {
		if (balance + amount < 0) throw new OverdraftException("Overdraft!");
		balance += amount;
	}

	@Override
	public double getBalance() {
		return balance;
	}

}
