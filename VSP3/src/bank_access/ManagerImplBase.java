package bank_access;

import mware_lib.IImplBase;

public abstract class ManagerImplBase implements IImplBase {
	public abstract String createAccount(String owner, String branch);

	public static ManagerImplBase narrowCast(Object o) {
		Object[] objRef = (Object[]) o;
		return new ManagerStub((String) objRef[0], (int) objRef[1], objRef[2]);
	}
	
	public ManagerSkeleton getSkeleton() {
		return new ManagerSkeleton(this);
	}
}