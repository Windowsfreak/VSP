package mware_lib.communication;

import java.io.IOException;
import java.net.ServerSocket;

public class Server {
	private ServerSocket socket;
	
	public Server(int listenPort) {
		try {
			socket = new ServerSocket(listenPort);
		} catch (IOException e) {
			throw new RuntimeException("Failed to start Server - listen port " + listenPort + " in use?", e);
		}		
	}
	
	public int getLocalPort() {
		return socket.getLocalPort();
	}
	
	public Connection getConnection() {
		try {
			return new Connection(socket.accept());
		} catch (IOException e) {
			throw new RuntimeException("Failed to accept connection", e);
		}
	}
	
	public void shutdown() {
		try {
			socket.close();
		} catch (IOException e) {
			throw new RuntimeException("Failed to stop Server", e);
		}
	}
}
