package sg.edu.nus.comp.pdtb.runners;

import java.io.IOException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.parser.ArgExtComp;
import sg.edu.nus.comp.pdtb.parser.ArgPosComp;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sg.edu.nus.comp.pdtb.parser.ExplicitComp;
import sg.edu.nus.comp.pdtb.parser.NonExplicitComp;

public class TrainPdtbParser {

	private static final Logger log = LogManager.getLogger(TrainPdtbParser.class.getName());

	public static void main(String[] args) throws IOException {

//		log.info("Training connective component.");
//		ConnComp connective = new ConnComp();
//		connective.train();
//
//		log.info("Training argument position classifier component.");
//		ArgPosComp argPos = new ArgPosComp();
//		argPos.train();
//
//		log.info("Training argument extractor component.");
//		ArgExtComp argExt = new ArgExtComp();
//		argExt.train();
//
//		log.info("Training explict component.");
//		ExplicitComp explicit = new ExplicitComp();
//		explicit.train();

		log.info("Training non-explict component.");
		NonExplicitComp nonExplicit = new NonExplicitComp();
		nonExplicit.train();
	}

}
