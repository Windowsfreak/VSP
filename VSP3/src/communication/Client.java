package communication;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.net.Socket;

public class Client {
	private Socket mySocket;
	private DataInputStream in;
	private DataOutputStream out;
	
	public Client(String host, int port) {
		try {
			mySocket = new Socket(host, port);
			
			in = new DataInputStream(mySocket.getInputStream());
			out = new DataOutputStream(mySocket.getOutputStream());
		} catch (Exception e) {
			throw new RuntimeException("Cannot establish connection to Server", e);
		}
	}
	
	public byte[] receive() {
		try {
			int length = in.readInt();
			byte[] data = new byte[length];
			in.readFully(data);
			close();
			return data;
		} catch (Exception e) {
			close();
			throw new RuntimeException("Failed to receive data from Server", e);
		}
	}
	
	public Client send(byte[] data) {
		try {
			out.writeInt(data.length);
			out.write(data);
			return this;
		} catch (Exception e) {
			throw new RuntimeException("Failed to send data to Server", e);
		}
	}
	
	public void close() {
		try {
			in.close();
			out.close();
			mySocket.close();
		} catch (Exception e) {
			throw new RuntimeException("Failed to terminate connection to Server", e);
		}
	}
}
