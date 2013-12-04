package mware_lib;

/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {
	private final String serviceName;
	private final int port;
	private NameService ns;
	
	private ObjectBroker(String serviceName, int port) {
		this.serviceName = serviceName;
		this.port = port;
	}

	/**
	 * @return an Implementation for a local NameService
	 */
	public NameService getNameService() {
		return (ns == null ? ns = new NameServiceStub(serviceName, port, null) : ns);
	}

	/**
	 * shuts down the process, the OjectBroker is running in terminates process
	 */
	public void shutdown() {
		//...
	}

	/**
	 * Initializes the ObjectBroker / creates the local NameService
	 * 
	 * @param serviceName hostname or IP of Nameservice
	 * @param port port NameService is listening at
	 * @return an ObjectBroker Interface to Nameservice
	 */
	public static ObjectBroker init(String serviceName, int port) {
		ObjectBroker ob = new ObjectBroker(serviceName, port);
		// ...
		return ob;
	}
}