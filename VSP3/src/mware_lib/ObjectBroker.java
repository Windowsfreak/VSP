package mware_lib;

import java.net.UnknownHostException;

import mware_lib.communication.ReceiverManager;
import mware_lib.communication.Server;


/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {
	private final String serviceName;
	private final int port;
	private int localPort;
	private final SkeletonStore skeletonStore;
	private NameService ns;
	private ReceiverManager receiverManager;
	
	private ObjectBroker(String serviceName, int port, int localPort, SkeletonStore skeletonStore) {
		this.serviceName = serviceName;
		this.port = port;
		this.localPort = localPort;
		this.skeletonStore = skeletonStore;
	}

	/**
	 * @return an Implementation for a local NameService
	 */
	public NameService getNameService() {
		try {
			return (ns == null ? ns = new NameServiceStub(serviceName, port, java.net.InetAddress.getLocalHost().getHostAddress(), localPort, skeletonStore) : ns);
		} catch (UnknownHostException e) {
			throw new RuntimeException("Could not find IP address", e);
		}
	}

	public void startup() {
		Server server = new Server(localPort);
		localPort = server.getLocalPort();
		receiverManager = new ReceiverManager(server, this);
		receiverManager.start();
	}
	
	public void join() {
		try {
			receiverManager.join();
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}
	
	/**
	 * shuts down the process, the OjectBroker is running in terminates process
	 */
	public void shutdown() {
		System.err.println("=== SHUTDOWN ===");
		receiverManager.shutDownServer();
		join();
	}

	/**
	 * Initializes the ObjectBroker / creates the local NameService
	 * 
	 * @param serviceName hostname or IP of Nameservice
	 * @param port port NameService is listening at
	 * @return an ObjectBroker Interface to Nameservice
	 */
	public static ObjectBroker init(String serviceName, int port) {
		return init(serviceName, port, 0);
	}
	
	public static ObjectBroker init(String serviceName, int port, int localPort) {
		SkeletonStore skeletonStore = new SkeletonStore();
		ObjectBroker ob = new ObjectBroker(serviceName, port, localPort, skeletonStore);
		ob.startup();
		return ob;
	}

	public SkeletonStore getSkeletonStore() {
		return skeletonStore;
	}
}