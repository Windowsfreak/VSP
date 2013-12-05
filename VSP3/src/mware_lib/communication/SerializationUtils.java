package mware_lib.communication;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import cash_access.OverdraftException;

public abstract class SerializationUtils {
/*	{
		// constructing a message
		Object[] requestMsg1 = generateRequest(obj, "transfer", 200);
		Object[] requestMsg2 = {obj, "transfer", new Object[] {200}};
		Object[] responseMsg1 = generateResponse("return", 400);
		Object[] responseMsg2 = {"return", 400};
		Object[] errorMsg1 = generateResponse("exception", new Exception());
		Object[] errorMsg2 = {"exception", new Exception()};
	}
*/	
	public static Object[] generateRequest(Object objRef, String methodName, Object... params) {
		return new Object[] {objRef, methodName, params};
	}
	public static Object[] generateResponse(String returnType, Object value) {
		return new Object[] {returnType, value};
	}
	public static Object getObjRef(Object requestMsg) {
		return ((Object[]) requestMsg)[0];
	}
	public static String getMethod(Object requestMsg) {
		return (String) ((Object[]) requestMsg)[1];
	}
	public static Object[] getParams(Object requestMsg) {
		return (Object[]) ((Object[]) requestMsg)[2];
	}
	public static boolean isException(Object responseMsg) {
		return ((Object[]) responseMsg)[0].equals("exception");
	}
	public static Object getResult(Object responseMsg) {
		return ((Object[]) responseMsg)[1];
	}
	public static Exception getException(Object responseMsg) {
		return (Exception) ((Object[]) responseMsg)[1];
	}
	public static byte[] serialize(Object[] obj) {
		try {
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			new ObjectOutputStream(baos).writeObject(obj);
			return baos.toByteArray();
		} catch (Exception e) {
			throw new RuntimeException("Failed to serialize object", e);
		}
	}
	public static Object[] deserialize(byte[] data) {
		try {
			ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(data));
			return(Object[]) ois.readObject();
		} catch (Exception e) {
			throw new RuntimeException("Failed to deserialize object", e);
		}
	}
	public static void throwException(Exception e) { // ???
		if (e instanceof RuntimeException) {
			throw (RuntimeException) e;
		}
	}
}
