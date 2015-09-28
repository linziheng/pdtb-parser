package sg.edu.nus.comp.pdtb.runners;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.parser.ArgExtComp;
import sg.edu.nus.comp.pdtb.parser.ArgPosComp;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sg.edu.nus.comp.pdtb.parser.ExplicitComp;
import sg.edu.nus.comp.pdtb.parser.NonExplicitComp;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Settings;

public class TrainBioDrb {

	private static final Logger log = LogManager.getLogger(TrainBioDrb.class.getName());

	public static void main(String[] args) throws IOException {

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

		log.info("Training the connective component");
		ConnComp connective = new ConnComp();
		connective.trainBioDrb();
		log.info("Done.");

		log.info("Training the argument position component");
		ArgPosComp argPos = new ArgPosComp();
		argPos.trainBioDrb();
		log.info("Done.");

		log.info("Training the argument extractor component");
		ArgExtComp argExt = new ArgExtComp();
		argExt.trainBioDrb();
		log.info("Done.");

		log.info("Training the explicit component");
		ExplicitComp exp = new ExplicitComp();
		exp.trainBioDrb();
		log.info("Done.");

		log.info("Training the non-explicit component - Implicit, AltLex and NoRel relations");
		NonExplicitComp nonExp = new NonExplicitComp();
		nonExp.trainBioDrb();
		log.info("Done.");
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
		File[] texts = new File(Settings.BIO_DRB_RAW_PATH).listFiles();
		for (int i = 0; i < texts.length; ++i) {
			File inputFile = texts[i];
			File treeFile = new File(Settings.BIO_DRB_TREE_PATH + inputFile.getName() + ".ptree");
			SpanTreeExtractor.anyTextToSpanGen(treeFile, inputFile);
		}
		log.info("Done.");
	}

	private static void generateTrees() throws IOException {

		log.info("Generating parse and dependecy trees for BioDRB corpus in: " + Settings.BIO_DRB_RAW_PATH);
		new File(Settings.BIO_DRB_TREE_PATH).mkdirs();
		log.info("Trees would be stored in: " + Settings.BIO_DRB_TREE_PATH);
		File[] texts = new File(Settings.BIO_DRB_RAW_PATH).listFiles();
		Corpus.prepareParseAndDependecyTrees(texts, Settings.BIO_DRB_TREE_PATH);
		log.info("Done generating trees.");
	}

}
