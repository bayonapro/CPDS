public class SavingAccount {

	public static void main(String ... args) {
		Account account = new Account();

		Thread a = new Person(account);
		a.setName("Alice");

		Thread b = new Person(account);
		b.setName("Bob");

		Thread c = new Company(account);
		c.setName("company");

		a.start();
		b.start();
		c.start();
	}
}
