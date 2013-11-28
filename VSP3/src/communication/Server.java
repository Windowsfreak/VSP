package communication;

import java.io.IOException;
import java.net.ServerSocket;

public class Server {
	private ServerSocket mySocket;
	
	public Server(int listenPort) throws IOException {
		mySocket = new ServerSocket(listenPort);		
	}
	
	public Connection getConnection() throws IOException {
		return new Connection(mySocket.accept());
	}
	
	public void shutdown() throws IOException {
		mySocket.close();
	}
}
