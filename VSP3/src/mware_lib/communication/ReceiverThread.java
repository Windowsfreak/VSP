package mware_lib.communication;

import mware_lib.ObjectBroker;
import mware_lib.Skeleton;
import mware_lib.SkeletonStore;

public class ReceiverThread extends Thread {

	private Connection connection;
	private SkeletonStore skeletonStore;

	public ReceiverThread(Connection socket, ObjectBroker broker) {
		this.connection = socket;
		this.skeletonStore = broker.getSkeletonStore();
	}

	protected void shutDownSocket() {
		try {
			connection.close();
		} catch (Exception e) {
		}
	}

	@Override
	public void run() {
		try {
			Object[] requestMsg = SerializationUtils.deserialize(connection
					.receive());
			Object objRef = SerializationUtils.getObjRef(requestMsg);
			Skeleton skeleton = this.skeletonStore.resolve(objRef);
			if (skeleton == null) {
				connection.send(SerializationUtils.serialize(SerializationUtils
						.generateResponse("exception", new RuntimeException(
								"Skeleton " + objRef + " not found"))));
			}
			connection.send(SerializationUtils.serialize(skeleton
					.remoteInvoke(requestMsg)));
			connection.close();
		} catch (Exception e) {
		}
	}
}