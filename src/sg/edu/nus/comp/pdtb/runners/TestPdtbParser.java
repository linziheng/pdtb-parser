package sg.edu.nus.comp.pdtb.runners;

import java.io.File;
import java.io.IOException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.parser.ArgExtComp;
import sg.edu.nus.comp.pdtb.parser.ArgPosComp;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sg.edu.nus.comp.pdtb.parser.ExplicitComp;
import sg.edu.nus.comp.pdtb.parser.NonExplicitComp;
import sg.edu.nus.comp.pdtb.util.Result;
import sg.edu.nus.comp.pdtb.util.Scorer;
import sg.edu.nus.comp.pdtb.util.Settings;

public class TestPdtbParser {

	private static final Logger log = LogManager.getLogger(TestPdtbParser.class.getName());
	private static final int[] EXPLICIT_COUNTS = { 712, 750, 713, 529, 822, 816, 653, 804, 176, 786, 720, 780, 800, 941,
			734, 868, 1092, 614, 898, 647, 724, 605, 680, 923, 672 };
	private static final int[] IMPLICIT_COUNTS = { 859, 885, 944, 627, 1017, 972, 741, 1007, 227, 957, 818, 1098, 957,
			1153, 1019, 949, 1302, 716, 1026, 810, 918, 759, 764, 1020, 596 };

	public static void main(String[] args) throws IOException {

		FeatureType[] testingsTypes = FeatureType.testingValues();

		for (FeatureType featureType : testingsTypes) {
			log.info("Testing on " + featureType);
			log.info("Testing connective component.");

			Scorer scorer = new Scorer();

			scorer.gsExplicit = sumGsInstances(EXPLICIT_COUNTS, Settings.TEST_SECTIONS);
			scorer.gsImplicit = sumGsInstances(IMPLICIT_COUNTS, Settings.TEST_SECTIONS);

			ConnComp connective = new ConnComp();
			File connResult = connective.test(featureType);

			Result connScore = scorer.conn(connective.getGsFile(featureType), connResult);
			log.info("GS");
			log.info("Acc:" + connScore.print(connScore.acc));
			log.info("F1:" + connScore.print(connScore.f1));

			scorer.prdExplicit = connScore.tp + connScore.fp;

			log.info("Testing argument position classifier component.");
			ArgPosComp argPos = new ArgPosComp();
			File argPosResult = argPos.test(featureType);
			Result argPosScore = scorer.argPos(argPos.getGsFile(featureType), argPosResult, featureType);
			log.info(argPosScore.printAll());

			log.info("Testing argument extractor component.");
			ArgExtComp argExt = new ArgExtComp();
			File argExtResult = argExt.test(featureType);
			Result[] argScore = scorer.argExtExact(argExtResult, featureType);
			log.info("\nEXACT \nA1: " + argScore[0].print(argScore[0].f1) + "\tA2: " + argScore[1].print(argScore[1].f1)
					+ "\tA1A2: " + argScore[2].print(argScore[2].f1));

			log.info("Testing explict component.");
			ExplicitComp explicit = new ExplicitComp();
			File expResult = explicit.test(featureType);
			Result expScore = scorer.exp(explicit.getGsFile(featureType), expResult, featureType);
			log.info(expScore.printAll());

			log.info("Testing non-explict component.");
			NonExplicitComp nonExplicit = new NonExplicitComp();
			File nonExpResult = nonExplicit.test(featureType);
			Result score = scorer.nonExp(nonExplicit.getGsFile(featureType), nonExpResult, featureType);
			log.info(score.printAll());

			log.info("Done testing.");
		}
	}

	private static int sumGsInstances(int[] explicitCounts, int[] testSection) {
		int count = 0;
		for (int section : testSection) {
			count += explicitCounts[section];
		}

		return count;
	}

}