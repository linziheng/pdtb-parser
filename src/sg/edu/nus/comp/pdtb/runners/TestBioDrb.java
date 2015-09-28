package sg.edu.nus.comp.pdtb.runners;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.parser.ArgExtComp;
import sg.edu.nus.comp.pdtb.parser.ArgPosComp;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sg.edu.nus.comp.pdtb.parser.ExplicitComp;
import sg.edu.nus.comp.pdtb.parser.NonExplicitComp;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Result;
import sg.edu.nus.comp.pdtb.util.Scorer;
import sg.edu.nus.comp.pdtb.util.Settings;

public class TestBioDrb {

	private static final Logger log = LogManager.getLogger(TestBioDrb.class.getName());

	public static Set<String> testSet = new HashSet<>();
	public static Set<String> trainSet = new HashSet<>();

	public static void main(String[] args) throws IOException {
		FeatureType[] testingsTypes = FeatureType.testingValues();
		String topOutPath = Settings.OUT_PATH;
		for (FeatureType featureType : testingsTypes) {

			int crossValidationK = 10;
			String[] scores = new String[crossValidationK * 5];

			for (int k = 0; k < crossValidationK; ++k) {

				splitSets(k);

				Settings.OUT_PATH = topOutPath + "CV_" + k + "/";
				new File(Settings.OUT_PATH).mkdirs();

				log.info("Testing on " + featureType);

				Scorer scorer = new Scorer();
				int gsExplicit = 0;
				for (String article : TestBioDrb.testSet) {
					gsExplicit += Corpus.getBioExplicitSpans(new File(article), featureType).size();
				}
				scorer.gsExplicit = gsExplicit;

				log.info("Testing connective component.");
				ConnComp connective = new ConnComp();
				connective.trainBioDrb();
				File connResult = connective.testBioDrb(featureType);
				Result connScore = scorer.connBio(connective.getGsFile(featureType), connResult);

				scorer.prdExplicit = connScore.tp + connScore.fp;
				
				
				log.info("Acc:" + connScore.print(connScore.acc));
				log.info("F1:" + connScore.print(connScore.f1));

				scores[k * 5] = "Connective: " + connScore.printAll();

				log.info("Testing argument position classifier component.");
				ArgPosComp argPos = new ArgPosComp();
				argPos.trainBioDrb();
				File argPosResult = argPos.testBioDrb(featureType);
				Result argPosScore = scorer.argPosBio(argPos.getGsFile(featureType), argPosResult, featureType);
				log.info(argPosScore.printAll());
				scores[k * 5 + 1] = "ArgPos: " + argPosScore.printAll();

				log.info("Testing argument extractor component.");
				ArgExtComp argExt = new ArgExtComp();
				argExt.trainBioDrb();
				File argExtResult = argExt.testBioDrb(featureType);
				Result[] argScore = scorer.argExtExact(argExtResult, featureType);
				log.info("\nEXACT A1:\tA2\tA1A2 \n" + argScore[0].print(argScore[0].f1) + "\t"
						+ argScore[1].print(argScore[1].f1) + "\t" + argScore[2].print(argScore[2].f1));

				scores[k * 5 + 2] = "\nEXACT A1:\tA2\tA1A2 \n" + argScore[0].print(argScore[0].f1) + "\t"
						+ argScore[1].print(argScore[1].f1) + "\t" + argScore[2].print(argScore[2].f1);

				log.info("Testing explict component.");
				ExplicitComp explicit = new ExplicitComp();
				explicit.trainBioDrb();
				File expResult = explicit.testBioDrb(featureType);
				Result expScore = scorer.exp(explicit.getGsFile(featureType), expResult, featureType);
				log.info(expScore.printAll());
				scores[k * 5 + 3] = "Explict: " + expScore.printAll();

				int gsImplicit = 0;
				for (String article : TestBioDrb.testSet) {
					gsImplicit += Corpus.getBioNonExplicitSpans(new File(article)).size();
				}

				scorer.gsImplicit = gsImplicit;

				log.info("Testing non-explict component.");
				NonExplicitComp nonExplicit = new NonExplicitComp();
				nonExplicit.trainBioDrb();
				File nonExpResult = nonExplicit.testBioDrb(featureType);
				Result score = scorer.nonExp(nonExplicit.getGsFile(featureType), nonExpResult, featureType);
				log.info(score.printAll());
				scores[k * 5 + 4] = "Implicit: " + score.printAll();
			}

			log.info("======SCORES======");
			for (int i = 0; i < scores.length; i += 5) {
				log.info("==================");
				log.info("CV " + i);
				splitSets(i);
				String tmp = "TestFiles: ";
				for (String fn : testSet) {
					tmp += fn + " ";
				}
				log.info(tmp);
				for (int j = 0; j < 5; ++j) {
					log.info(scores[i + j]);
				}
				log.info("==================");
			}

		}

	}

	private static void splitSets(int k) {
		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith("txt");
			}
		});

		testSet.clear();
		trainSet.clear();
		// 24 total/ 10 = 2
		int testFile1 = k * 2;
		int testFile2 = testFile1 + 1;

		for (int i = 0; i < files.length; ++i) {
			String filename = files[i].getName();
			if (i == testFile1 || i == testFile2) {
				testSet.add(filename);
			} else {
				trainSet.add(filename);
			}
		}
	}
}
