package nameservice;

import mware_lib.NameService;
import mware_lib.Skeleton;
import communication.SerializationUtils;

public class NameServiceSkeleton implements Skeleton {
	NameService object;

	public NameServiceSkeleton(NameService object) {
		this.object = object;
	}
	
	public Object[] remoteInvoke(Object[] requestMsg) {
		String method = SerializationUtils.getMethod(requestMsg);
		switch (method) {
		case "rebind":
			try {
				object.rebind(SerializationUtils.getParams(requestMsg)[0], (String) SerializationUtils.getParams(requestMsg)[1]);
				return SerializationUtils.generateResponse("void", null);
			} catch (Exception e) {
				return SerializationUtils.generateResponse("exception", e);
			}
		case "resolve":
			return SerializationUtils.generateResponse("return", object.resolve((String) SerializationUtils.getParams(requestMsg)[0]));
		default:
			return SerializationUtils.generateResponse("exception", new RuntimeException("Methode " + method + " nicht gefunden."));
		}
	}

}
