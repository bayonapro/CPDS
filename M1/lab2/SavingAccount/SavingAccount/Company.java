import java.util.Random;

public class Company extends Thread {
    Account account;
    Random random = new Random();

    public Company(Account account) {
        this.account = account;
    }

    public void run() {
        String name = Thread.currentThread().getName();
        while(true) {
            int amount = random.nextInt(100);
            System.out.println(name + " would like to deposit");
            try {
                Thread.sleep(200);
                account.deposit(amount);
            } catch (InterruptedException e) {}
        }
    }
}
