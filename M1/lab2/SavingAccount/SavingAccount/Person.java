import java.util.Random;

public class Person extends Thread {
	Account account;
	int max_movement;

	Random random = new Random();

	public Person(Account account, int max_movement) {
		this.account = account;
		this.max_movement = max_movement;
	}

	public void run() {
		String name = Thread.currentThread().getName();
		while(true) {
			int amount = random.nextInt(100); // 100 is an arbitrary number 
			if (random.nextBoolean()) {
				System.out.println(name + " would like to deposit");
				try {
					Thread.sleep(200);
					account.deposit(amount);
				} catch (InterruptedException e) {}
			} else {
				System.out.println(name + " would like to withdraw");
				try {
					Thread.sleep(200);
					account.withdraw(amount);
				} catch (InterruptedException e) {}
			}
		}
	}
}
