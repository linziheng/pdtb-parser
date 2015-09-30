package sg.edu.nus.comp.pdtb.runners;

import static sg.edu.nus.comp.pdtb.util.Corpus.PIPE_FILTER;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Result;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

public class ScorePdtbOnBioDrb {

	private static Logger log = LogManager.getLogger(ScorePdtbOnBioDrb.class.toString());

	public static void runScorer(String pdtbFolder, String bioDrbFolder) throws IOException {
		File[] pdtbPipes = new File(pdtbFolder).listFiles(PIPE_FILTER);
		File[] tmpPipes = new File(bioDrbFolder).listFiles(PIPE_FILTER);

		Map<String, File> bioPipes = new HashMap<>();
		for (File file : tmpPipes) {
			bioPipes.put(file.getName(), file);
		}

		int gsExplicit = 2636;
		int gsNonExplicit = 3001 + 193 + 29; // implicit + altlex + norel

		int predExplicit = 0;
		int predNonExplicit = 0;

		int correctConnective = 0;
		int correctArg1Exact = 0;
		int correctArg2Exact = 0;
		int correctArg12Exact = 0;
		int correctExplicit = 0;
		int correctNonExplicit = 0;

		for (File pdtbPipe : pdtbPipes) {

			File bioPipeFile = bioPipes.get(pdtbPipe.getName());
			String[] bioTemp = Util.readFile(bioPipeFile).split(Util.NEW_LINE);

			Map<String, String> explicitSpans = extractExplicit(bioTemp);
			String[] bioNonExplicit = extractNonExplicit(bioTemp);

			String[] pipes = Util.readFile(pdtbPipe).split(Util.NEW_LINE);

			for (String pipe : pipes) {
				String[] columns = pipe.split("\\|", -1);

				String type = columns[0];
				String connective = columns[3];
				String sense = columns[11];
				String arg1 = columns[22];
				String arg2 = columns[32];

				if (type.equals("Explicit")) {
					++predExplicit;

					String bioPipe = explicitSpans.get(connective);
					if (bioPipe != null) {
						++correctConnective;
						String[] bioColumns = bioPipe.split("\\|", -1);
						String bioSense = bioColumns[8];
						String bioArg1 = bioColumns[14];
						String bioArg2 = bioColumns[20];

						boolean senseMatch = compareSense(sense, bioSense);
						boolean arg1Match = compareArg(arg1, bioArg1);
						boolean arg2Match = compareArg(arg2, bioArg2);

						if (senseMatch) {
							++correctExplicit;
						}
						if (arg1Match) {
							++correctArg1Exact;
						}
						if (arg2Match) {
							++correctArg2Exact;
						}
						if (arg1Match && arg2Match) {
							++correctArg12Exact;
						}
					}
				} else {
					++predNonExplicit;
					// search for pipes
					for (String bioPipe : bioNonExplicit) {
						String[] bioColumns = bioPipe.split("\\|", -1);

						String bioSense = bioColumns[8];
						String bioArg1 = bioColumns[14];
						String bioArg2 = bioColumns[20];

						boolean arg1Match = compareArg(arg1, bioArg1);
						boolean arg2Match = compareArg(arg2, bioArg2);

						if (arg1Match && arg2Match) {
							boolean senseMatch = compareSense(sense, bioSense);
							if (senseMatch) {
								++correctNonExplicit;
							}
						}
					}
				}
			}
		}

		log.info("Scores");
		log.info("Connective");
		log.info(Result.calcResults(gsExplicit, predExplicit, correctConnective).printAll());

		log.info("Argument 1 Exact");
		log.info(Result.calcResults(gsExplicit, predExplicit, correctArg1Exact).printAll());

		log.info("Argument 2 Exact");
		log.info(Result.calcResults(gsExplicit, predExplicit, correctArg2Exact).printAll());

		log.info("Both Arguments Exact");
		log.info(Result.calcResults(gsExplicit, predExplicit, correctArg12Exact).printAll());

		log.info("Explicit Sense");
		log.info(Result.calcResults(gsExplicit, predExplicit, correctExplicit).printAll());

		log.info("NonExplicit (Implicit, AltLex and NoRel) Sense");
		log.info(Result.calcResults(gsNonExplicit, predNonExplicit, correctNonExplicit).printAll());

	}

	private static boolean compareArg(String thisArg, String thatArg) {

		if (thisArg.isEmpty() || thatArg.isEmpty()) {
			return false;
		}

		String[] thisSpans = thisArg.split(";");
		String[] thatSpans = thatArg.split(";");

		int allowedDifference = 1;
		boolean hasMatch = false;

		if (thisSpans.length == thatSpans.length) {

			for (String thisSpanString : thisSpans) {
				for (String thatSpanString : thatSpans) {
					int[] thisSpan = Corpus.spanToInt(thisSpanString);
					int[] thatSpan = Corpus.spanToInt(thatSpanString);

					hasMatch = Math.abs(thisSpan[0] - thatSpan[0]) < allowedDifference;
					hasMatch &= Math.abs(thisSpan[1] - thatSpan[1]) < allowedDifference;

					if (!hasMatch) {
						break;
					}
				}
				if (!hasMatch) {
					break;
				}
			}

		}

		return hasMatch;
	}

	private static boolean compareSense(String pdtbSense, String bioSense) {

		String bioLevel1Sense = Util.extractSemantic(bioSense, Settings.SEMANTIC_LEVEL);
		String pdtbLevel1Sense = Util.extractSemantic(pdtbSense, Settings.SEMANTIC_LEVEL);

		boolean hasMatch = false;
		switch (pdtbLevel1Sense) {

		case "Comparison": {
			hasMatch = bioLevel1Sense.equalsIgnoreCase("Concession");
			hasMatch |= bioLevel1Sense.equalsIgnoreCase("Contrast");
			break;
		}

		case "Contingency": {
			hasMatch = bioLevel1Sense.equalsIgnoreCase("Cause");
			hasMatch |= bioLevel1Sense.equalsIgnoreCase("Condition");
			hasMatch |= bioLevel1Sense.equalsIgnoreCase("Purpose");
			break;
		}

		case "Temporal": {
			hasMatch = bioLevel1Sense.equalsIgnoreCase("Temporal");
			break;
		}

		case "Expansion": {
			String[] matches = { "Alternative", "Background", "Circumstance", "Conjunction", "Continuation",
					"Exception", "Instantiation", "Reinforcement", "Restatement", "Similarity" };

			for (String match : matches) {
				hasMatch |= bioLevel1Sense.equalsIgnoreCase(match);
			}
			break;
		}
		}

		return hasMatch;
	}

	private static String[] extractNonExplicit(String[] pipes) {
		List<String> temp = new ArrayList<>();
		for (String pipe : pipes) {
			String[] cols = pipe.split("\\|", -1);
			if (!cols[0].equals("Explicit")) {
				temp.add(pipe);
			}
		}
		return temp.toArray(new String[temp.size()]);
	}

	/**
	 * Key connective span Value pipe
	 * 
	 * @param pipes
	 * @return
	 */
	private static Map<String, String> extractExplicit(String[] pipes) {
		Map<String, String> map = new HashMap<>();
		for (String pipe : pipes) {
			String[] cols = pipe.split("\\|", -1);
			if (cols[0].equals("Explicit")) {
				map.put(cols[1], pipe);
			}
		}
		return map;
	}
}
