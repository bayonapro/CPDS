public class Account {
	int balance = 0;

	public Account() {
	}

	public synchronized void deposit_old(int amount) throws InterruptedException {
		// Condition synchronization: the amount to deposit + balance is less or equal than the capacity
		// otherwise, wait till this condition is satisfied
		// This could derivate into a deadlock, should be fixed
	//	if (balance + amount > capacity) {
			System.out.println(Thread.currentThread().getName() + " has to wait");
			wait();
		// }

		balance += amount;
		notifyAll();

		print_balance();
	}

	public synchronized void deposit(int amount) throws InterruptedException {
		// This function only deposits money
		// if (balance + amount > capacity) {
		// 	System.out.println(Thread.currentThread().getName() + " has to wait");
		// 	wait();
		// }

                System.out.println(Thread.currentThread().getName() + " has deposited " + amount);
		balance += amount;
		notifyAll();

		print_balance();
	}

	public synchronized void withdraw(int amount) throws InterruptedException {
		// Condition synchronization: the amount to withdraw has to be less or equal than the balance
		// otherwise, wait till this condition is satisfied
		while (amount > balance) {
			System.out.println(Thread.currentThread().getName() + " has to wait");
			wait();
		}
                System.out.println(Thread.currentThread().getName() + " has withdrawn " + amount);

		balance -= amount;
                // notifyAll();

                print_balance();
	}

	public synchronized void print_balance() {
		System.out.println("current balance in the account: " + balance);
	}
}
