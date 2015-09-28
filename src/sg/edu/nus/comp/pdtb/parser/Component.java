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

package sg.edu.nus.comp.pdtb.parser;

import static sg.edu.nus.comp.pdtb.util.Settings.OUT_PATH;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Corpus.Type;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

/**
 * Common class for parser component.
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public abstract class Component {

	protected static Logger log = null;

	protected String name = "not_set";
	protected String modelFilePath;
	protected File modelFile;
	protected File gsFile;

	public Component(String name, String className) {
		log = LogManager.getLogger(className);
		this.name = name;
		this.modelFilePath = OUT_PATH + name + ".model";
		this.modelFile = new File(modelFilePath);
	}

	public abstract List<String[]> generateFeatures(File article, FeatureType featureType) throws IOException;

	public abstract List<String[]> generateFeatures(Type corpus, File article, FeatureType featureType)
			throws IOException;

	public abstract File parseAnyText(File modelFile, File inputFile) throws IOException;

	public File parseAnyText(File inputFile) throws IOException {
		return parseAnyText(modelFile, inputFile);
	};

	public File train() throws IOException {
		File trainFile = printFeaturesToFile(FeatureType.Training);
		File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);
		return modelFile;
	}

	public File test(File model, FeatureType featureType) throws IOException {
		File testFile = printFeaturesToFile(featureType);
		String fileName = Settings.OUT_PATH + this.name + featureType.toString() + ".out";
		File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(fileName));

		return outFile;
	}

	public File test(FeatureType featureType) throws IOException {
		return test(modelFile, featureType);
	}

	private File printFeaturesToFile(FeatureType featureType) throws IOException {
		return printFeaturesToFile(Type.PDTB, featureType);
	}

	private File printFeaturesToFile(Type corpus, FeatureType featureType) throws IOException {

		String name = this.name + featureType.toString();

		String dir = OUT_PATH + name.replace('.', '_') + "/";
		new File(dir).mkdirs();

		File testFile = new File(OUT_PATH + name);
		PrintWriter featureFile = new PrintWriter(testFile);

		log.info("Printing " + featureType + " features: ");
		int[] sections = (featureType == FeatureType.Training) ? Settings.TRAIN_SECTIONS : Settings.TEST_SECTIONS;
		for (int section : sections) {
			log.info("Section: " + section);
			File[] files = Corpus.getSectionFiles(section);

			for (File file : files) {
				log.trace("Article: " + file.getName());

				String articleId = file.getName().substring(0, 8);
				String articleName = dir + articleId;
				File articleTest = new File(articleName + ".features");
				PrintWriter articleFeatures = new PrintWriter(articleTest);

				File auxFile = new File(articleName + ".aux");
				PrintWriter auxFileWriter = new PrintWriter(auxFile);

				List<String[]> features = generateFeatures(corpus, file, featureType);
				for (String[] feature : features) {
					featureFile.println(feature[0]);
					articleFeatures.println(feature[0]);
					if (feature.length > 1 && !this.getClass().equals(NonExplicitComp.class)) {
						String headSpan = Corpus.calculateHeadSpan(feature[1]);
						auxFileWriter.println(headSpan);
					}
				}
				featureFile.flush();
				articleFeatures.close();
				auxFileWriter.close();

				if (featureType.isTestingType() && this.getClass().equals(ExplicitComp.class) && features.size() > 0) {
					File articleOut = MaxEntClassifier.predict(articleTest, modelFile, new File(articleName + ".out"));
					String pipeDir = OUT_PATH + "pipes" + featureType.toString().replace('.', '_');
					new File(pipeDir).mkdirs();
					makeExpPipeFile(pipeDir, articleOut, auxFile, file.getName());
				}
			}
		}
		featureFile.close();

		return testFile;
	}

	private void makeExpPipeFile(String pipeDir, File articleOut, File auxFile, String article) throws IOException {
		File pipeFile = new File(pipeDir + "/" + article);
		String[] lines = Util.readFile(pipeFile).split(Util.NEW_LINE);
		Map<String, String> spanToPipe = new HashMap<>();
		for (String pipe : lines) {
			String[] cols = pipe.split("\\|", -1);
			spanToPipe.put(cols[3], pipe);
		}
		if (spanToPipe.size() > 0) {
			PrintWriter pipeWriter = new PrintWriter(pipeFile);
			try (BufferedReader reader = Util.reader(auxFile)) {
				try (BufferedReader outReader = Util.reader(articleOut)) {
					String span;
					while ((span = reader.readLine()) != null) {
						String[] out = outReader.readLine().split("\\s+");
						String sense = Corpus.getFullSense(out[out.length - 1]);
						String[] cols = spanToPipe.get(span).split("\\|", -1);
						StringBuilder newPipe = new StringBuilder();

						for (int i = 0; i < cols.length; ++i) {
							if (i == 11) {
								newPipe.append(sense);
							} else {
								newPipe.append(cols[i]);
							}
							newPipe.append('|');
						}
						newPipe.deleteCharAt(newPipe.length() - 1);
						pipeWriter.println(newPipe);
					}
				}
			}
			pipeWriter.close();
		}
	}

	public File getModelFile() {
		return modelFile;
	}

	public File getGsFile() {
		return gsFile;
	}

	public File getGsFile(FeatureType type) {
		this.gsFile = new File(OUT_PATH + name + type);
		return gsFile;
	}

	public String getModelFilePath() {
		return this.modelFilePath;
	}

	public void setModelFilePath(String modelFilePath) {
		this.modelFilePath = modelFilePath;
	}
}
