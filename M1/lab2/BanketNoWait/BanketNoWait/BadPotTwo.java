public class BadPotTwo {
	private int servings = 0;
	private int capacity;

	public BadPotTwo(int capacity) {
		this.capacity = capacity;
	}

	public synchronized void getserving() throws InterruptedException {
		// Condition synchronization: at least one serving available,
		// otherwise, go to the Waiting Set till the cook fill the pot
		if (servings == 0) {
			System.out.println(Thread.currentThread().getName() + " go walk");
		} else {
			Thread.sleep(200);
			--servings;
			System.out.println(Thread.currentThread().getName() + " is served");
			print_servings();
		}
	}

	public synchronized void fillpot() throws InterruptedException {
		if (servings > 0) {
			System.out.println(Thread.currentThread().getName() + " go walk");
		} else {
			servings = capacity;
			System.out.println(Thread.currentThread().getName() + " fills the pot");
			print_servings();
		}
	}

	//only for trace purposes
	public synchronized void print_servings() {
		System.out.println("servings in the pot: " + servings);
	}
}
