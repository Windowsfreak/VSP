package mware_lib;

import java.util.HashMap;
import java.util.Map;

public class SkeletonStore {
	// Object is actually of type String!
	private Map<Object, Skeleton> skeletons = new HashMap<Object, Skeleton>();

	public void rebind(Skeleton skeleton, Object name) {
		this.skeletons.put(name, skeleton);
	}

	public Skeleton resolve(Object name) {
		return this.skeletons.get(name);
	}

}