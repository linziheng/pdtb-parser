/**
 * Copyright (C) 2014 WING, NUS and NUS NLP Group.
 * 
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program. If
 * not, see http://www.gnu.org/licenses/.
 */

package sg.edu.nus.comp.pdtb.model;

import static sg.edu.nus.comp.pdtb.util.Util.NEW_LINE;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class Score {

	private boolean hasConnectives = false;
	private boolean hasSemanticClass = false;

	private int connectivesCorrect = 0;
	private int semanticClassCorrect = 0;
	private int arg1Correct = 0;
	private int arg2Correct = 0;

	private int expectedTotal = 0;
	private int predictedTotal = 0;

	private int expSemanticTotal = 0;
	private int predSemanticTotal = 0;

	private int expConnTotal = 0;
	private int predConnTotal = 0;

	@Override
	public String toString() {
		return printEvalMetrics();
	}

	private String printEvalMetrics() {
		StringBuilder sb = new StringBuilder();

		if (hasConnectives) {
			if (expConnTotal == 0 && expectedTotal > 0) {
				expConnTotal = expectedTotal;
			}
			if (predConnTotal == 0 && predictedTotal > 0) {
				predConnTotal = predictedTotal;
			}

			sb.append("Connective:" + NEW_LINE);
			sb.append("================================");
			sb.append(NEW_LINE);
			sb.append(printMetric(connectivesCorrect, expConnTotal, predConnTotal));
			sb.append(NEW_LINE);
		}
		if (hasSemanticClass) {

			if (expSemanticTotal == 0 && expectedTotal > 0) {
				expSemanticTotal = expectedTotal;
			}
			if (predSemanticTotal == 0 && predictedTotal > 0) {
				predSemanticTotal = predictedTotal;
			}
			// TODO change this back to semantic
			sb.append("Arg1 & Arg2:" + NEW_LINE);
			sb.append("================================");
			sb.append(NEW_LINE);
			sb.append(printMetric(semanticClassCorrect, expSemanticTotal, predSemanticTotal));
			sb.append(NEW_LINE);
		}
		sb.append("Arg1:" + NEW_LINE);
		sb.append("================================");
		sb.append(NEW_LINE);

		sb.append(printMetric(arg1Correct, expectedTotal, predictedTotal));
		sb.append(NEW_LINE);

		sb.append("Arg2:" + NEW_LINE);
		sb.append("================================");
		sb.append(NEW_LINE);
		sb.append(printMetric(arg2Correct, expectedTotal, predictedTotal));
		sb.append(NEW_LINE);

		return sb.toString();
	}

	private static String printMetric(int metricCorrect, int expectedTotal, int predictedTotal) {

		double recall = (100.0 * metricCorrect / expectedTotal);
		double precision = (100.0 * metricCorrect / predictedTotal);
		double f1 = (2 * recall * precision) / (recall + precision);

		StringBuilder sb = new StringBuilder();
		sb.append("Predicted total: " + predictedTotal + NEW_LINE);
		sb.append(" Expected total: " + expectedTotal + NEW_LINE);
		sb.append("        Correct: " + metricCorrect + NEW_LINE);
		sb.append("      Incorrect: " + (predictedTotal - metricCorrect) + NEW_LINE);
		sb.append("         Recall: " + String.format("%.2f", recall) + "%" + NEW_LINE);
		sb.append("      Precision: " + String.format("%.2f", precision) + "%" + NEW_LINE);
		sb.append("             F1: " + String.format("%.2f", f1) + "%" + NEW_LINE);

		return sb.toString();
	}

	public Score(int expectedTotal, int predictedTotal) {
		this.expectedTotal = expectedTotal;
		this.predictedTotal = predictedTotal;
	}

	public void incSemanticClass() {
		if (!hasSemanticClass) {
			throw new IllegalStateException("The scorer should not count semantic class. ");
		}
		++semanticClassCorrect;
	}

	public void incArg2() {
		++arg2Correct;
	}

	public void incArg1() {
		++arg1Correct;
	}

	public void incConnective() throws IllegalStateException {
		if (!hasConnectives) {
			throw new IllegalStateException("The scorer should not count connectives.");
		}
		++connectivesCorrect;
	}

	public int getConnectivesCorrect() {
		return connectivesCorrect;
	}

	public int getArg1Correct() {
		return arg1Correct;
	}

	public int getArg2Correct() {
		return arg2Correct;
	}

	public int getSemanticClassCorrect() {
		return semanticClassCorrect;
	}

	public int getExpectedTotal() {
		return expectedTotal;
	}

	public int getPredictedTotal() {
		return predictedTotal;
	}

	public void setHasConnectives(boolean hasConnectives) {
		this.hasConnectives = hasConnectives;
	}

	public void setHasSemanticClass(boolean hasSemanticClass) {
		this.hasSemanticClass = hasSemanticClass;
	}

	public void setExpSemanticTotal(int expSemanticTotal) {
		this.expSemanticTotal = expSemanticTotal;
	}

	public void setPredSemanticTotal(int predSemanticTotal) {
		this.predSemanticTotal = predSemanticTotal;
	}

	public void setExpConnTotal(int expConnTotal) {
		this.expConnTotal = expConnTotal;
	}

	public void setPredConnTotal(int predConnTotal) {
		this.predConnTotal = predConnTotal;
	}
}
