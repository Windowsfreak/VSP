package bank_access;

public class OverdraftException extends Exception {
	private static final long serialVersionUID = -1080515700023202592L;

	public OverdraftException(String msg) {
		super(msg);
	}
}