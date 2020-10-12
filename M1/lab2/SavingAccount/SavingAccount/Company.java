import java.util.Random;

public class Company extends Thread {
	Account account;
	int max_movement;
	Random random = new Random();

	public Company(Account account, int max_movement) {
		this.account = account;
		this.max_movement = max_movement;
	}

	public void run() {
		String name = Thread.currentThread().getName();
		while(true) {
			int amount = random.nextInt(2);
			if (random.nextBoolean()) {
				System.out.println(name + " would like to deposit");
				try {
					Thread.sleep(200);
					account.deposit(max_movement);
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
