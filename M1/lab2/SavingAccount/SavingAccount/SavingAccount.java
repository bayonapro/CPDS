public class SavingAccount {

	public static final int N = 1000;

	public static void main(String ... args) {
		Account account = new Account(N);

		Thread a = new Person(account, N);
		a.setName("Alice");

		Thread b = new Person(account, N);
		b.setName("Bob");

		Thread c = new Company(account, N);
		c.setName("company");

		a.start();
		b.start();
		c.start();
	}
}
