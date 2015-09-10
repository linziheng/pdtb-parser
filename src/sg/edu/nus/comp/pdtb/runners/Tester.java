/**
 * Copyright (C) 2015 WING, NUS and NUS NLP Group.
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
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Scorer.Result;

public class Tester {
	private static final Logger log = LogManager.getLogger(Tester.class.getName());

	public static void main(String[] args) throws IOException {
		if (args.length == 1 && args[0].equals("-useOldModels")) {
			testConn(false);
			testArgPos(false);
			testExp(false);
			testNonExp(false);
			testArgExt(false);
		} else {
			testConn(true);
			testArgPos(true);
			testExp(true);
			testNonExp(true);
			testArgExt(true);
		}
	}

	private static void testArgExt(boolean train) throws IOException {
		log.info("ArgExt component");
		ArgExtComp argExt = new ArgExtComp();
		if (train) {
			argExt.train();
		}

		for (FeatureType featureType : FeatureType.testingValues()) {
			log.info("Testing " + featureType);
			File resultPipeFile;
			if (featureType == FeatureType.Auto) {
				resultPipeFile = new File(Settings.OUT_PATH + ArgExtComp.NAME + featureType + ".args");
			} else {
				argExt.test(featureType);
				resultPipeFile = argExt.generateArguments(featureType);

			}
			Result[] score = Scorer.argExtExact(resultPipeFile, featureType);
			log.info("\nEXACT \nA1: " + score[0].print(score[0].f1) + "\tA2: " + score[1].print(score[1].f1)
					+ "\tA1A2: " + score[2].print(score[2].f1));

			score = Scorer.argExtPartial(resultPipeFile, featureType);
			log.info("\nPARTIAL\nA1: " + score[0].print(score[0].f1) + "\tA2: " + score[1].print(score[1].f1)
					+ "\tA1A2: " + score[2].print(score[2].f1));

		}
	}

	public static void testNonExp(boolean train) throws IOException {
		log.info("NonExplicit component");
		NonExplicitComp nonExp = new NonExplicitComp();
		if (train) {
			nonExp.train();
		}

		for (FeatureType featureType : FeatureType.testingValues()) {
			log.info("Testing " + featureType);
			File resultFile = nonExp.test(featureType);
			Result score = Scorer.nonExp(nonExp.getGsFile(featureType), resultFile, featureType);
			log.info(score.printAll());
		}

	}

	public static void testExp(boolean train) throws IOException {
		log.info("Explicit component");
		ExplicitComp exp = new ExplicitComp();
		if (train) {
			exp.train();
		}

		for (FeatureType featureType : FeatureType.testingValues()) {
			log.info("Testing " + featureType);
			File resultFile;
			if (featureType == FeatureType.Auto) {
				resultFile = new File(Settings.OUT_PATH + ExplicitComp.NAME + featureType + ".out");
			} else {
				resultFile = exp.test(featureType);
			}
			Result score = Scorer.exp(exp.getGsFile(featureType), resultFile, featureType);
			log.info(score.printAll());
		}

	}

	public static void testArgPos(boolean train) throws IOException {
		log.info("ArgPos component");
		ArgPosComp argPos = new ArgPosComp();
		if (train) {
			argPos.train();
		}

		for (FeatureType featureType : FeatureType.testingValues()) {
			log.info("Testing " + featureType);
			File resultFile;
			if (featureType == FeatureType.Auto) {
				resultFile = new File(Settings.OUT_PATH + ArgPosComp.NAME + featureType + ".out");
			} else {
				resultFile = argPos.test(featureType);
			}
			Result score = Scorer.argPos(argPos.getGsFile(featureType), resultFile, featureType);
			log.info(score.printAll());
		}

	}

	public static void testConn(boolean train) throws IOException {
		ConnComp conn = new ConnComp();
		log.info("Connective component");
		if (train) {
			conn.train();
		}
		File gsResultFile = conn.test(FeatureType.GoldStandard);

		Result res = Scorer.conn(conn.getGsFile(), gsResultFile);
		log.info("GS");
		log.info("Acc:" + res.print(res.acc));
		log.info("F1:" + res.print(res.f1));

	}
}
