package bank_access;

import communication.SerializationUtils;

public class ManagerSkeleton {

	ManagerImplBase object;

	public ManagerSkeleton(ManagerImplBase object) {
		this.object = object;
	}
	
	public Object[] remoteInvoke(Object[] requestMsg) {
		String method = SerializationUtils.getMethod(requestMsg);
		switch (method) {
		case "createAccount":
			try {
				String account = object.createAccount((String) SerializationUtils.getParams(requestMsg)[0], (String) SerializationUtils.getParams(requestMsg)[1]);
				return SerializationUtils.generateResponse("return", account);
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		default:
			return SerializationUtils.generateResponse("exception", new RuntimeException("Methode " + method + " nicht gefunden."));
		}
	}
}
