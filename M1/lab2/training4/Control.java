public class Control {
    int count = 0;
    boolean opened = false;

    public synchronized void arrive() throws InterruptedException {
		// Condition synchronization: the museum has to be open
		// otherwise, wait till the director opens it
		while (!opened) {
			System.out.println(Thread.currentThread().getName() + " has to wait");
			wait();
        }

        // update count
		++count;
		System.out.println(Thread.currentThread().getName() + " has entered the museum");

		print_visitors();
		notifyAll();
    }

    public synchronized void leave() throws InterruptedException {
		// Condition synchronization: there's at least one person at the museum
		// otherwise, wait till there's one visitor
        while (count <= 0) {
			System.out.println("There's no one at the museum");
			wait();
        }

        
		// update count
		--count;

        if (count == 0) notifyAll();
		print_visitors();

    }

    public synchronized void open() throws InterruptedException {
		// Condition synchronization: the museum is closed
		// otherwise, wait till the museum is closed and empty
		while(opened && count > 0) {
			System.out.println(Thread.currentThread().getName() + ": museum is  already open");
			wait();
		}

		opened = true;
		notifyAll();
    }

    public synchronized void close() throws InterruptedException {
		// Condition synchronization: the museum is open
		// otherwise, wait till the museum is open
        while(!opened) {
			System.out.println(Thread.currentThread().getName() + ": museum is already closed");
			wait();
		}

		opened = false;
		notifyAll();
    }

	public synchronized void print_visitors() {
		System.out.println("visitors at the museum: " + count);
	}
}
