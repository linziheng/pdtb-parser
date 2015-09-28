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

public class TestPdtbParser {

	private static final Logger log = LogManager.getLogger(TestPdtbParser.class.getName());

	public static void main(String[] args) throws IOException {

		FeatureType[] testingsTypes = FeatureType.testingValues();

		for (FeatureType featureType : testingsTypes) {
			log.info("Testing on " + featureType);
			log.info("Testing connective component.");

			Scorer scorer = new Scorer();

			scorer.gsExplicit = 923;
			scorer.gsImplicit = 1017;

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

}