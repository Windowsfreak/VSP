package bank_access;

import communication.Client;
import communication.SerializationUtils;

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
		return (String) SerializationUtils.getResult(responseMsg);
	}

}
