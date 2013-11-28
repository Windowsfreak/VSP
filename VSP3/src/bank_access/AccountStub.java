package bank_access;

import communication.Client;
import communication.SerializationUtils;

public class AccountStub extends AccountImplBase {
	private final String host;
	private final int port;
	private final Object objRef;
	public AccountStub(String host, int port, Object objRef) {
		this.host = host;
		this.port = port;
		this.objRef = objRef;
	}

	@Override
	public void transfer(double amount) throws OverdraftException {
		Object[] responseMsg = SerializationUtils.deserialize(
					new Client(host, port).send(
						SerializationUtils.serialize(
							SerializationUtils.generateRequest(objRef, "transfer", amount)
						)
					).receive()
				);
		
		if (SerializationUtils.isException(responseMsg)) {
			Exception e = SerializationUtils.getException(responseMsg);
			if (e instanceof OverdraftException)
				throw (OverdraftException) e;
			else if (e instanceof RuntimeException)
				throw (RuntimeException) e;
			else
				throw new RuntimeException("Unexpected Exception type", e);
		}
	}

	@Override
	public double getBalance() {
		Object[] responseMsg =
				SerializationUtils.deserialize(
					new Client(host, port).send(
						SerializationUtils.serialize(
							SerializationUtils.generateRequest(objRef, "getBalance")
						)
					).receive()
				);

		return (double) SerializationUtils.getResult(responseMsg);
	}

}
