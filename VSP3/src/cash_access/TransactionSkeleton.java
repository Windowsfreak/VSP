package cash_access;

import mware_lib.Skeleton;
import communication.SerializationUtils;

public class TransactionSkeleton implements Skeleton {
	TransactionImplBase object;

	public TransactionSkeleton(TransactionImplBase object) {
		this.object = object;
	}
	
	public Object[] remoteInvoke(Object[] requestMsg) {
		String method = SerializationUtils.getMethod(requestMsg);
		switch (method) {
		case "deposit":
			try {
				object.deposit((String) SerializationUtils.getParams(requestMsg)[0], (double) SerializationUtils.getParams(requestMsg)[1]);
				return SerializationUtils.generateResponse("void", null);
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		case "withdraw":
			try {
				object.withdraw((String) SerializationUtils.getParams(requestMsg)[0], (double) SerializationUtils.getParams(requestMsg)[1]);
				return SerializationUtils.generateResponse("void", null);
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		case "getBalance":
			try {
				return SerializationUtils.generateResponse("return", object.getBalance((String) SerializationUtils.getParams(requestMsg)[0]));
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		default:
			return SerializationUtils.generateResponse("exception", new RuntimeException("Methode " + method + " nicht gefunden."));
		}
	}

}
