package mware_lib;

/**
 * core of the middleware: Maintains a Reference to the NameService Singleton
 */
public class ObjectBroker {
	/**
	 * @return an Implementation for a local NameService
	 */
	public NameService getNameService() {
		//...
		return null;
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
		//...
		return null;
	}
}