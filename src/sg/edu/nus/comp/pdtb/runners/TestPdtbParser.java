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
import sg.edu.nus.comp.pdtb.util.Scorer;
import sg.edu.nus.comp.pdtb.util.Scorer.Result;

public class TestPdtbParser {

	private static final Logger log = LogManager.getLogger(TestPdtbParser.class.getName());

	public static void main(String[] args) throws IOException {

		FeatureType[] testingsTypes = FeatureType.testingValues();

		for (FeatureType featureType : testingsTypes) {
			log.info("Testing on " + featureType);
			log.info("Testing connective component.");
			ConnComp connective = new ConnComp();
			File connResult = connective.test(featureType);

			Result res = Scorer.conn(connective.getGsFile(featureType), connResult);
			log.info("GS");
			log.info("Acc:" + res.print(res.acc));
			log.info("F1:" + res.print(res.f1));

			log.info("Testing argument position classifier component.");
			ArgPosComp argPos = new ArgPosComp();
			File argPosResult = argPos.test(featureType);
			Result argPosScore = Scorer.argPos(argPos.getGsFile(featureType), argPosResult, featureType);
			log.info(argPosScore.printAll());

			log.info("Testing argument extractor component.");
			ArgExtComp argExt = new ArgExtComp();
			File argExtResult = argExt.test(featureType);
			Result[] argScore = Scorer.argExtExact(argExtResult, featureType);
			log.info("\nEXACT \nA1: " + argScore[0].print(argScore[0].f1) + "\tA2: " + argScore[1].print(argScore[1].f1)
					+ "\tA1A2: " + argScore[2].print(argScore[2].f1));

			log.info("Testing explict component.");
			ExplicitComp explicit = new ExplicitComp();
			File expResult = explicit.test(featureType);
			Result expScore = Scorer.exp(explicit.getGsFile(featureType), expResult, featureType);
			log.info(expScore.printAll());

			log.info("Testing non-explict component.");
			NonExplicitComp nonExplicit = new NonExplicitComp();
			File nonExpResult = nonExplicit.test(featureType);
			Result score = Scorer.nonExp(nonExplicit.getGsFile(featureType), nonExpResult, featureType);
			log.info(score.printAll());
		}
	}

}
// TODO check the score
