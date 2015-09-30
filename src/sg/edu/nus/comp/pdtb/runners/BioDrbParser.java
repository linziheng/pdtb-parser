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

public class BioDrbParser {

	private static Logger log = LogManager.getLogger(BioDrbParser.class.toString());
	public static Set<String> TEST_SET = new HashSet<>();
	public static Set<String> TRAIN_SET = new HashSet<>();

	public static void main(String[] args) throws IOException {
		if (args.length > 0) {
			if (args[0].equals("--train-only")) {
				trainOnly();
			} else if (args[0].equals("--cross-validation")) {
				crossValidation();
			} else if (args[0].equals("--score-pdtb")) {
				if (args.length > 2) {
					ScorePdtbOnBioDrb.runScorer(args[1], args[2]);
				} else {
					log.error("Please supply the pdtb pipes directory and bio pipes directory as program arguments.");
				}
			} else {
				log.error("Invalid program arguments.");
			}
		} else {
			log.error("Please supply one of the program arguments below:");
			log.error(" --train-only \t\t\t\t\t  : build a biodrb model using all articles");
			log.error(" --cross-validation \t\t\t\t  : do 10-fold cross validation");
			log.error(" --score-pdtb pdtb_pipe_folder biodrb_pipe_folder : score the PDTB parser on the BioDRB corpus");
		}
	}

	public static void crossValidation() throws IOException {

		checkAuxFiles();

		FeatureType[] testingsTypes = FeatureType.testingValues();
		String topOutPath = Settings.MODEL_PATH;
		for (FeatureType featureType : testingsTypes) {

			int crossValidationK = 10;
			String[] scores = new String[crossValidationK * 5];

			for (int k = 0; k < crossValidationK; ++k) {

				splitSets(k);

				Settings.MODEL_PATH = topOutPath + "CV_" + k + "/";
				new File(Settings.MODEL_PATH).mkdirs();

				log.info("Testing on " + featureType);

				Scorer scorer = new Scorer();
				int gsExplicit = 0;
				for (String article : TEST_SET) {
					gsExplicit += Corpus.getBioExplicitSpans(new File(article), featureType).size();
				}
				scorer.gsExplicit = gsExplicit;

				log.info("Testing connective component.");
				ConnComp connective = new ConnComp();
				connective.trainBioDrb(TRAIN_SET);
				File connResult = connective.testBioDrb(TEST_SET, featureType);
				Result connScore = scorer.connBio(connective.getGsFile(featureType), connResult);

				scorer.prdExplicit = connScore.tp + connScore.fp;
				log.info("Connective score: ");
				log.info("Acc:" + connScore.print(connScore.acc));
				log.info("F1:" + connScore.print(connScore.f1));

				scores[k * 5] = "Connective: " + connScore.printAll();

				log.info("Testing argument position classifier component.");
				ArgPosComp argPos = new ArgPosComp();
				argPos.trainBioDrb(TRAIN_SET);
				File argPosResult = argPos.testBioDrb(TEST_SET, featureType);
				Result argPosScore = scorer.argPosBio(argPos.getGsFile(featureType), argPosResult, featureType);

				log.info("Argument Position: ");
				log.info(argPosScore.printAll());
				scores[k * 5 + 1] = "ArgPos: " + argPosScore.printAll();

				log.info("Testing argument extractor component.");
				ArgExtComp argExt = new ArgExtComp();
				argExt.trainBioDrb(TRAIN_SET);
				File argExtResult = argExt.testBioDrb(TEST_SET, featureType);
				Result[] argScore = scorer.argExtExact(argExtResult, featureType);
				log.info("Argument Extractor:");
				log.info("\nEXACT A1:\tA2\tA1A2 \n" + argScore[0].print(argScore[0].f1) + "\t"
						+ argScore[1].print(argScore[1].f1) + "\t" + argScore[2].print(argScore[2].f1));

				scores[k * 5 + 2] = "\nEXACT A1:\tA2\tA1A2 \n" + argScore[0].print(argScore[0].f1) + "\t"
						+ argScore[1].print(argScore[1].f1) + "\t" + argScore[2].print(argScore[2].f1);

				log.info("Testing explict component.");
				ExplicitComp explicit = new ExplicitComp();
				explicit.trainBioDrb(TRAIN_SET);
				File expResult = explicit.testBioDrb(TEST_SET, featureType);
				Result expScore = scorer.exp(explicit.getGsFile(featureType), expResult, featureType);
				log.info(expScore.printAll());
				scores[k * 5 + 3] = "Explict: " + expScore.printAll();

				int gsImplicit = 0;
				for (String article : TEST_SET) {
					gsImplicit += Corpus.getBioNonExplicitSpans(new File(article)).size();
				}

				scorer.gsImplicit = gsImplicit;

				log.info("Testing non-explict component.");
				NonExplicitComp nonExplicit = new NonExplicitComp();
				nonExplicit.trainBioDrb(TRAIN_SET);
				File nonExpResult = nonExplicit.testBioDrb(TEST_SET, featureType);
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
				for (String fn : TEST_SET) {
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
		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(Corpus.TXT_FILTER);

		TEST_SET.clear();
		TRAIN_SET.clear();
		// 24 total/ 10 = 2
		int testFile1 = k * 2;
		int testFile2 = testFile1 + 1;

		for (int i = 0; i < files.length; ++i) {
			String filename = files[i].getName();
			if (i == testFile1 || i == testFile2) {
				TEST_SET.add(filename);
			} else {
				TRAIN_SET.add(filename);
			}
		}
	}

	public static void trainOnly() throws IOException {

		checkAuxFiles();

		File[] texts = new File(Settings.BIO_DRB_RAW_PATH).listFiles(Corpus.TXT_FILTER);
		for (File file : texts) {
			TRAIN_SET.add(file.getName());
		}

		log.info("Training the connective component");
		ConnComp connective = new ConnComp();
		connective.trainBioDrb(TRAIN_SET);
		log.info("Done.");

		log.info("Training the argument position component");
		ArgPosComp argPos = new ArgPosComp();
		argPos.trainBioDrb(TRAIN_SET);
		log.info("Done.");

		log.info("Training the argument extractor component");
		ArgExtComp argExt = new ArgExtComp();
		argExt.trainBioDrb(TRAIN_SET);
		log.info("Done.");

		log.info("Training the explicit component");
		ExplicitComp exp = new ExplicitComp();
		exp.trainBioDrb(TRAIN_SET);
		log.info("Done.");

		log.info("Training the non-explicit component - Implicit, AltLex and NoRel relations");
		NonExplicitComp nonExp = new NonExplicitComp();
		nonExp.trainBioDrb(TRAIN_SET);
		log.info("Done.");
	}

	private static void checkAuxFiles() throws IOException {
		if (!(new File(Settings.BIO_DRB_RAW_PATH).exists())) {
			log.error("BioDRB corpus not found in " + Settings.BIO_DRB_RAW_PATH + "");
			System.exit(1);
		}
		if (!(new File(Settings.BIO_DRB_TREE_PATH).exists())) {
			log.info("Parse and dependecy trees not found.");
			generateTrees();
		}
		if (!treeSpansExist()) {
			log.info("Parse tree text spans not found.");
			generateTreeSpans();
		}

		if (!expSpansExist()) {
			log.info("Explicit spans not found.");
			SpanTreeExtractor.expBioSpansGen();
		}
	}

	private static boolean expSpansExist() {
		return new File(Settings.BIO_DRB_TREE_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".hw");
			}
		}).length > 0;
	}

	private static boolean treeSpansExist() {
		return new File(Settings.BIO_DRB_TREE_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".csv");
			}
		}).length > 0;
	}

	private static void generateTreeSpans() throws IOException {
		log.info("Generating parse tree nodes text spans. The spans are stored in the tree folder as csv files.");
		File[] texts = new File(Settings.BIO_DRB_RAW_PATH).listFiles(Corpus.TXT_FILTER);
		for (int i = 0; i < texts.length; ++i) {
			File inputFile = texts[i];
			log.info("Processing file: " + inputFile);
			File treeFile = new File(Settings.BIO_DRB_TREE_PATH + inputFile.getName() + ".ptree");
			SpanTreeExtractor.anyTextToSpanGen(treeFile, inputFile);
		}
		log.info("Done.");
	}

	private static void generateTrees() throws IOException {

		log.info("Generating parse and dependecy trees for BioDRB corpus in: " + Settings.BIO_DRB_RAW_PATH);
		new File(Settings.BIO_DRB_TREE_PATH).mkdirs();
		log.info("Trees would be stored in: " + Settings.BIO_DRB_TREE_PATH);
		File[] texts = new File(Settings.BIO_DRB_RAW_PATH).listFiles(Corpus.TXT_FILTER);
		Corpus.prepareParseAndDependecyTrees(texts, Settings.BIO_DRB_TREE_PATH);
		log.info("Done generating trees.");
	}
}
