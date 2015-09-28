package sg.edu.nus.comp.pdtb.util;

public class Result {

	public double prec;
	public double recall;
	public double f1;
	public double acc;
	public int tp;
	public int fp;
	public int fn;
	public int tn;

	public static Result calcResults(double gsTotal, double prdTotal, int correct) {

		double p = prdTotal == 0 ? 0 : (1.0 * correct / prdTotal) * 100;
		double r = gsTotal == 0 ? 0 : (1.0 * correct / gsTotal) * 100;
		double f1 = (2 * p * r) / (r + p);

		return new Result(p, r, f1, -1);
	}

	Result(double p, double r, double f1, double acc) {
		prec = p;
		recall = r;
		this.f1 = f1;
		this.acc = acc;
	}

	public String print(double num) {
		return String.format("%.2f", num);
	}

	public String printAll() {
		return "\n\nPrec\tRecall\tF1\n" + print(prec) + "\t" + print(recall) + "\t" + print(f1)+"\n";
	}
}