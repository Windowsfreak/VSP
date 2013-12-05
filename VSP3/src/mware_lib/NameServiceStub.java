package mware_lib;

import mware_lib.communication.Client;
import mware_lib.communication.SerializationUtils;

public class NameServiceStub extends NameService {
	private final String host;
	private final int port;
	private final String localHost;
	private final int localPort;
	private final Object objRef;
	private SkeletonStore skeletonStore;
	public NameServiceStub(String host, int port, String localHost, int localPort, SkeletonStore skeletonStore) {
		this.host = host;
		this.port = port;
		this.localHost = localHost;
		this.localPort = localPort;
		this.objRef = "NameService";
		this.skeletonStore = skeletonStore;
	}

	@Override
    public void rebind(Object servant, String name) {
		Object[] objRefStr = {localHost, localPort, name};
		Object[] responseMsg = SerializationUtils.deserialize(
				new Client(host, port).send(
					SerializationUtils.serialize(
						SerializationUtils.generateRequest(objRef, "rebind", objRefStr, name)
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
		
		skeletonStore.rebind(((IImplBase) servant).getSkeleton(), name);
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