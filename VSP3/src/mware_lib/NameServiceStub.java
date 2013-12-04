package mware_lib;

import communication.Client;
import communication.SerializationUtils;

public class NameServiceStub extends NameService {
	private final String host;
	private final int port;
	private final Object objRef;
	public NameServiceStub(String host, int port, Object objRef) {
		this.host = host;
		this.port = port;
		this.objRef = objRef;
	}

	@Override
    public void rebind(Object servant, String name) {
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "rebind", servant, name)
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
	}

	@Override
	public Object resolve(String name) {
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "resolve", name)
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

		return SerializationUtils.getResult(responseMsg);
	}
}