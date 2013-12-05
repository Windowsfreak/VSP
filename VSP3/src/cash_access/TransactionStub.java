package cash_access;

import mware_lib.communication.Client;
import mware_lib.communication.SerializationUtils;

public class TransactionStub extends TransactionImplBase {
	private final String host;
	private final int port;
	private final Object objRef;
	public TransactionStub(String host, int port, Object objRef) {
		this.host = host;
		this.port = port;
		this.objRef = objRef;
	}

	@Override
	public void deposit(String accountId, double amount)
			throws InvalidParamException {
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "deposit", accountId, amount)
					)
				).receive()
			);
	
		if (SerializationUtils.isException(responseMsg)) {
			Exception e = SerializationUtils.getException(responseMsg);
			if (e instanceof InvalidParamException)
				throw (InvalidParamException) e;
			else if (e instanceof RuntimeException)
				throw (RuntimeException) e;
			else
				throw new RuntimeException("Unexpected Exception type", e);
		}
	}

	@Override
	public void withdraw(String accountId, double amount)
			throws InvalidParamException, OverdraftException {
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "withdraw", accountId, amount)
					)
				).receive()
			);
	
		if (SerializationUtils.isException(responseMsg)) {
			Exception e = SerializationUtils.getException(responseMsg);
			if (e instanceof InvalidParamException)
				throw (InvalidParamException) e;
			if (e instanceof OverdraftException)
				throw (OverdraftException) e;
			else if (e instanceof RuntimeException)
				throw (RuntimeException) e;
			else
				throw new RuntimeException("Unexpected Exception type", e);
		}
	}

	@Override
	public double getBalance(String accountId) throws InvalidParamException {
		Object[] responseMsg =
				SerializationUtils.deserialize(
					new Client(host, port).send(
						SerializationUtils.serialize(
							SerializationUtils.generateRequest(objRef, "getBalance", accountId)
						)
					).receive()
				);

		if (SerializationUtils.isException(responseMsg)) {
			Exception e = SerializationUtils.getException(responseMsg);
			if (e instanceof InvalidParamException)
				throw (InvalidParamException) e;
			else if (e instanceof RuntimeException)
				throw (RuntimeException) e;
			else
				throw new RuntimeException("Unexpected Exception type", e);
		}

		return (double) SerializationUtils.getResult(responseMsg);
	}

}
