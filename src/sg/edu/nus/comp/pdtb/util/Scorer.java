package sg.edu.nus.comp.pdtb.util;

/**
 * 
 * Copyright (C) 2014-2015 WING, NUS and NUS NLP Group.
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
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import sg.edu.nus.comp.pdtb.model.FeatureType;

/**
 * @author ilija.ilievski@u.nus.edu
 */
public class Scorer {

	public int gsExplicit;
	public int prdExplicit;

	public int prdImplicit;
	public int gsImplicit;

	public Result conn(File gsFile, File pdFile) throws IOException {

		int[] counts = countConn(gsFile, pdFile);

		int tp = counts[0], fn = counts[1], fp = counts[2], tn = counts[3];

		fn = gsExplicit - tp;

		double p = (tp + fp) == 0 ? 0 : tp * 100.0 / (tp + fp);
		double r = (tp + fn) == 0 ? 0 : tp * 100.0 / (tp + fn);
		double f1 = (p + r) == 0 ? 0 : 2 * p * r / (p + r);
		double acc = (tp + tn) * 100.0 / (tp + fp + fn + tn);

		Result result = new Result(p, r, f1, acc);
		result.tp = tp;
		result.fp = fp;
		result.fn = fn;
		result.tn = tn;
		return result;
	}

	public Result argPos(File gsFile, File pdFile, FeatureType featureType) throws IOException {

		int correct = countMatches(gsFile, pdFile);
		return Result.calcResults(gsExplicit, prdExplicit, correct);
	}

	public Result argPosBio(File gsFile, File pdFile, FeatureType featureType) throws IOException {
		int correct = countMatches(gsFile, pdFile);

		return Result.calcResults(gsExplicit, prdExplicit, correct);
	}

	public Result exp(File gsFile, File pdFile, FeatureType featureType) throws IOException {

		int correct = countSenseTypes(gsFile, pdFile);

		Result score = Result.calcResults(gsExplicit, prdExplicit, correct);
		return score;
	}

	public Result nonExp(File gsFile, File pdFile, FeatureType featureType) throws IOException {

		int correct = countSenseTypes(gsFile, pdFile);
		Result score = Result.calcResults(gsImplicit, prdImplicit, correct);
		return score;
	}

	private int countSenseTypes(File expFile, File prdFile) throws IOException {
		int c = 0;
		int t = 0;
		
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(expFile), Util.ENCODING))) {
			try (BufferedReader read = new BufferedReader(
					new InputStreamReader(new FileInputStream(prdFile), Util.ENCODING))) {
				String eTmp;
				String pTmp;
				while ((eTmp = reader.readLine()) != null) {
					pTmp = read.readLine();
					String[] exp = eTmp.split("\\s+");
					String[] prd = pTmp.split("\\s+");
					String[] tmp = exp[exp.length - 1].split("£");

					if (tmp[0].equals(prd[prd.length - 1]) || (tmp.length > 1 && tmp[1].equals(prd[prd.length - 1]))) {
						++c;
					}
					++t;
				}
			}
		}
		prdImplicit = t;

		return c;
	}

	private int countMatches(File gsFile, File pdFile) throws IOException {
		int c = 0;
		try (BufferedReader eR = new BufferedReader(
				new InputStreamReader(new FileInputStream(gsFile), Util.ENCODING))) {
			try (BufferedReader pR = new BufferedReader(
					new InputStreamReader(new FileInputStream(pdFile), Util.ENCODING))) {
				String eTmp;
				String pTmp;
				while ((pTmp = pR.readLine()) != null) {
					eTmp = eR.readLine();

					String[] exp = eTmp.split("\\s+");
					String[] prd = pTmp.split("\\s+");
					if (exp[exp.length - 1].equals(prd[prd.length - 1])) {
						++c;
					}
				}
			}
		}
		return c;
	}

	private int[] countConn(File gsFile, File pdFile) throws IOException {
		int tp = 0, fn = 0, fp = 0, tn = 0;

		try (BufferedReader gsRead = new BufferedReader(
				new InputStreamReader(new FileInputStream(gsFile), Util.ENCODING))) {
			try (BufferedReader pdRead = new BufferedReader(
					new InputStreamReader(new FileInputStream(pdFile), Util.ENCODING))) {
				String expected;
				while ((expected = gsRead.readLine()) != null) {
					String predicted = pdRead.readLine();
					expected = " " + expected;
					int expConn = Integer.parseInt(expected.substring(expected.lastIndexOf(' ')).trim());
					int prdConn = Integer.parseInt(predicted.substring(predicted.lastIndexOf(' ')).trim());

					if (prdConn == 1 && expConn == 1) {
						++tp;
					} else if (prdConn == 0 && expConn == 1) {
						++fn;
					} else if (prdConn == 1 && expConn == 0) {
						++fp;
					} else if (prdConn == 0 && expConn == 0) {
						++tn;
					}
				}
			}
		}

		return new int[] { tp, fn, fp, tn };
	}

	public Result[] argExtExact(File resultPipeFile, FeatureType featureType) throws IOException {
		int arg1Correct = 0;
		int arg2Correct = 0;
		int bothCorrect = 0;
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(resultPipeFile), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] args = line.split("\\|", -1);
				boolean arg1Match = args[4].equals(args[6]) || exactMatch(args[0], args[2]);
				boolean arg2Match = args[5].equals(args[7]) || exactMatch(args[1], args[3]);
				if (arg1Match) {
					++arg1Correct;
				}
				if (arg2Match) {
					++arg2Correct;
				}
				if (arg1Match && arg2Match) {
					++bothCorrect;
				}
			}
		}

		return new Result[] { Result.calcResults(gsExplicit, prdExplicit, arg1Correct),
				Result.calcResults(gsExplicit, prdExplicit, arg2Correct),
				Result.calcResults(gsExplicit, prdExplicit, bothCorrect) };
	}

	private boolean exactMatch(String expected, String predicted) {

		expected = regexSafe(expected);
		predicted = regexSafe(predicted);
		String eStriped = expected.replaceAll(predicted, "").trim();
		String pStriped = predicted.replaceAll(expected, "").trim();
		String[] eParts = eStriped.split("\\b");
		String[] pParts = pStriped.split("\\b");
		if (((eParts.length == 1) && !eStriped.equals(expected.trim()))
				|| ((pParts.length == 1) && !pStriped.equals(predicted.trim()))) {
			return true;
		}
		return false;
	}

	public boolean partMatch(String expected, String predicted) {

		expected = regexSafe(expected);
		predicted = regexSafe(predicted);
		String[] eParts = expected.split("\\b");
		String[] pParts = predicted.split("\\b");

		for (String eWord : eParts) {
			for (String pWord : pParts) {
				if (eWord.equals(pWord)) {
					return eWord.length() > 0;
				}
			}
		}

		return false;
	}

	private static String regexSafe(String string) {
		return string.replaceAll("\\{|\\}|\\[|\\]|\\(|\\)|\\&", "").trim();
	}

	public Result[] argExtPartial(File resultPipeFile, FeatureType featureType) throws IOException {
		int arg1Correct = 0;
		int arg2Correct = 0;
		int bothCorrect = 0;
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(resultPipeFile), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] args = line.split("\\|", -1);
				boolean arg1Match = args[4].equals(args[6]) || partMatch(args[0], args[2]);
				boolean arg2Match = args[5].equals(args[7]) || partMatch(args[1], args[3]);
				if (arg1Match) {
					++arg1Correct;
				}
				if (arg2Match) {
					++arg2Correct;
				}
				if (arg1Match && arg2Match) {
					++bothCorrect;
				}
			}
		}

		return new Result[] { Result.calcResults(gsExplicit, prdExplicit, arg1Correct),
				Result.calcResults(gsExplicit, prdExplicit, arg2Correct),
				Result.calcResults(gsExplicit, prdExplicit, bothCorrect) };
	}

	public Result connBio(File gsFile, File connResult) throws IOException {
		return conn(gsFile, connResult);
	}

}
