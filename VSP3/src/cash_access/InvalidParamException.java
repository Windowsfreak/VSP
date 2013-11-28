package cash_access;

public class InvalidParamException extends Exception {
	private static final long serialVersionUID = 5017834091223757869L;

	public InvalidParamException(String message) {
		super(message);
	}
}