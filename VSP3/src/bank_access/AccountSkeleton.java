package bank_access;

import mware_lib.Skeleton;
import mware_lib.communication.SerializationUtils;

public class AccountSkeleton implements Skeleton {
	AccountImplBase object;

	public AccountSkeleton(AccountImplBase object) {
		this.object = object;
	}
	
	public Object[] remoteInvoke(Object[] requestMsg) {
		String method = SerializationUtils.getMethod(requestMsg);
		switch (method) {
		case "transfer":
			try {
				object.transfer((double) SerializationUtils.getParams(requestMsg)[0]);
				return SerializationUtils.generateResponse("void", null);
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		case "getBalance":
			return SerializationUtils.generateResponse("return", object.getBalance());
		default:
			return SerializationUtils.generateResponse("exception", new RuntimeException("Methode " + method + " nicht gefunden."));
		}
	}

}
