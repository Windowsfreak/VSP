package name_service;

import mware_lib.ObjectBroker;

public class NameServiceStarter {
	public static void main(String[] args) {
		ObjectBroker ob = ObjectBroker.init("localhost", 10000, 10000);
		new NameService().submit(ob);
		ob.join();
	}
}
