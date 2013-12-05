package bank_access;

import mware_lib.communication.Client;
import mware_lib.communication.SerializationUtils;

public class ManagerStub extends ManagerImplBase {
	private final String host;
	private final int port;
	private final Object objRef;
	public ManagerStub(String host, int port, Object objRef) {
		this.host = host;
		this.port = port;
		this.objRef = objRef;
	}

	@Override
	public String createAccount(String owner, String branch) {
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "createAccount", owner, branch)
					)
				).receive()
			);

		if (SerializationUtils.isException(responseMsg)) {
			Exception e = SerializationUtils.getException(responseMsg);
			if (e instanceof RuntimeException)
				throw (RuntimeException) e;
			else
				throw new RuntimeException("Unexpected Exception type", e);
		}
		
		return (String) SerializationUtils.getResult(responseMsg);
	}

}
