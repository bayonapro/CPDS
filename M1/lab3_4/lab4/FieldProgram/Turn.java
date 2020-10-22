public class Turn {
	private int turn;

	public Turn() {
		turn = 1;
	}

	public synchronized boolean my_turn(String s) {
		// no condition synchronized is needed
		if (s.equals("alice")) return turn == 1;
		return turn == 2;
	}

	public synchronized void set_turn(String s) {
		// no condition synchronized is needed
		if (s.equals("alice")) turn = 2;
		else turn = 1;
	}

	public synchronized void print_turn() {
		System.out.println("Turn is: " + turn);
	}
}
