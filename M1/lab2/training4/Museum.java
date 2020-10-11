public class Museum {
	public static void main(String ... args) {
		Control control = new Control();

		Thread director = new Director(control);
		director.setName("Director");
		
		Thread[] easts = {
			new East(control),
			new East(control),
			new East(control),
			new East(control),
			new East(control)
		};

		Thread[] wests = {
			new West(control),
			new West(control),
			new West(control),
			new West(control),
			new West(control)
		};

		director.start();

		for (Thread t : easts) {
			t.start();
		}

		for (Thread t : wests) {
			t.start();
		}
	}
}
