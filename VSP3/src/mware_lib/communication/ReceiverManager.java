package mware_lib.communication;

import java.util.LinkedList;

import mware_lib.ObjectBroker;

public class ReceiverManager extends Thread {
	private LinkedList<ReceiverThread> receiverThreads;
	private Server server;
	private ObjectBroker broker;
	private boolean exit = false;

	public ReceiverManager(Server server, ObjectBroker broker) {
		receiverThreads = new LinkedList<>();
		this.server = server;
		this.broker = broker;
	}

	public synchronized void addReceiverThread(ReceiverThread rt) {
		this.receiverThreads.add(rt);
	}

	public synchronized void removeReceiverThread(ReceiverThread rt) {
		this.receiverThreads.remove(rt);
	}

	public void run() {
		Connection connection;

		while (!exit) {
			try {
				connection = server.getConnection();
				ReceiverThread thread = new ReceiverThread(connection, broker);
				thread.start();
				this.addReceiverThread(thread);
				this.removeDeadThreads();
			} catch (Exception e) {
				throw new RuntimeException(e);
			}
		}
		closeAllThreads();
	}

	private synchronized void removeDeadThreads() {
		ReceiverThread rt;
		for (int i = receiverThreads.size() - 1; i >= 0; i--) {
			rt = receiverThreads.get(i);
			if (!rt.isAlive()) {
				receiverThreads.remove(rt);
			}
		}
	}

	private synchronized void closeAllThreads() {
		for (ReceiverThread rt : this.receiverThreads) {
			try {
				rt.shutDownSocket();
				rt.join();
			} catch (InterruptedException e) {
				throw new RuntimeException(e);
			}
		}
	}

	public void shutDownServer() {
		this.exit = true;
		server.shutdown();
	}
}