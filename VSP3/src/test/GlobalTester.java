package test;

import name_service.NameServiceStarter;

public class GlobalTester {

	/**
	 * @param args
	 * @throws InterruptedException 
	 */
	public static void main(String[] args) throws InterruptedException {
		System.out.println("testing SE");
		Thread se = new Thread() {
			public void run() {
				SerializationTester.main(new String[] {});
			}
		};
		se.start();
		Thread.sleep(1000);
		System.out.println("testing NS");
		Thread ns = new Thread() {
			public void run() {
				NameServiceStarter.main(new String[] {});
			}
		};
		ns.start();
		Thread.sleep(1000);
		System.out.println("testing BA");
		Thread ba = new Thread() {
			public void run() {
				BankTester.main(new String[] {});
			}
		};
		ba.start();
		Thread.sleep(1000);
		System.out.println("testing FI");
		Thread fi = new Thread() {
			public void run() {
				FilialeTester.main(new String[] {});
			}
		};
		fi.start();
		Thread.sleep(1000);
		System.out.println("testing GE");
		Thread ge = new Thread() {
			public void run() {
				GeldautomatTester.main(new String[] {});
			}
		};
		ge.start();
	}

}
