
public class Neighbor extends Thread {
	
	private Flags flags;

	public Neighbor(Flags flags) {
		this.flags = flags;
	}

	// Basic solution
//	public void run() {
//		while(true) {
//			try {
//				String name = Thread.currentThread().getName();
//				System.out.println("try again, my name is: " + name);
//				Thread.sleep((int) (200 * Math.random()));
//				flags.set_true(name);
//				System.out.println(name + " flag up");
//				if (!flags.query_flag(name)) {
//					System.out.println(name + " enter");
//					Thread.sleep(400);
//					System.out.println(name + " exits");
//				}
//				Thread.sleep((int) (200 * Math.random()));
//				flags.set_false(name);
//				System.out.println(name + " flag down");
//			} catch(InterruptedException e) {};
//		}
//	}

	// Greedy solution
	public void run() {
		while(true) {
			try {
				String name = Thread.currentThread().getName();
				System.out.println("try again, my name is: " + name);
				// We comment the sleep in order to obtain the greedy behaviour
				// Thread.sleep((int) (200 * Math.random()));
				flags.set_true(name);
				// System.out.println(name + " flag up");
				if (!flags.query_flag(name)) {
					System.out.println(name + " enter");
					Thread.sleep(400);
					System.out.println(name + " exits");
				}
				Thread.sleep((int) (200 * Math.random()));
				flags.set_false(name);
				// System.out.println(name + " flag down");
			} catch(InterruptedException e) {};
		}
	}
}
