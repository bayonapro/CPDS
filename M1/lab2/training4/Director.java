public class Director extends Thread {
	Control control;

	public Director(Control control) {
		this.control = control;
	}

	public void run() {
		String name = Thread.currentThread().getName();

		while (true) {
			System.out.println(name + " would like to open the museum");
			try {
				Thread.sleep(200);
				control.open();
			} catch(InterruptedException e) {};

			System.out.println(name + " would like to close the museum");
			try {
				Thread.sleep(200);
				control.close();
			} catch(InterruptedException e) {};
		}
	}
}
