package test;

import cash_access.OverdraftException;
import static mware_lib.communication.SerializationUtils.*;

public class SerializationTester {

	public static void main(String[] args) {
		System.out.println("test procedure start");
		Object[] a = generateRequest("obj1337", "transfer", 200);
		Object[] b = deserialize(serialize(a));
		System.out.println(getMethod(b));
		Object[] c = generateResponse("exception", new OverdraftException("hello world"));
		Object[] d = deserialize(serialize(c));
		System.out.println(getException(d).getMessage());
	}

}
