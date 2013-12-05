package mware_lib.communication;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.Socket;

public class Connection {
	private DataInputStream in;
	private DataOutputStream out;
	
	public Connection(Socket mySocket) throws IOException {
		in = new DataInputStream(mySocket.getInputStream());
		out = new DataOutputStream(mySocket.getOutputStream());
	}
	
	public byte[] receive() throws IOException {
		int length = in.readInt();
		byte[] data = new byte[length];
		in.readFully(data);
		return data;
	}
	
	public void send(byte[] data) throws IOException {
		out.writeInt(data.length);
		out.write(data);
	}
	
	public void close() throws IOException {
		in.close();
		out.close();
	}
}
