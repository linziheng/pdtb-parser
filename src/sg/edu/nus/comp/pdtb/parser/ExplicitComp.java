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

import static sg.edu.nus.comp.pdtb.util.Settings.MODEL_PATH;
import static sg.edu.nus.comp.pdtb.util.Settings.OUTPUT_FOLDER_NAME;

import java.io.BufferedReader;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import edu.stanford.nlp.trees.Tree;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.model.Node;
import sg.edu.nus.comp.pdtb.runners.TestBioDrb;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Corpus.Type;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class ExplicitComp extends Component {
	public static final String NAME = "exp";

	public ExplicitComp() {
		super(NAME, ExplicitComp.class.getName());
	}

	@Override
	public List<String[]> generateFeatures(File article, FeatureType featureType) throws IOException {
		return generateFeatures(Type.PDTB, article, featureType);
	}

	public List<String[]> generateFeatures(Type corpus, File article, FeatureType featureType) throws IOException {
		List<String[]> features = new ArrayList<>();

		ArrayList<String> spanMap = null;

		Map<String, String> spanHashMap = null;
		List<String> explicitSpans = null;
		List<Tree> trees;

		if (corpus.equals(Type.PDTB)) {
			spanMap = Corpus.getSpanMapAsList(article, featureType);
			spanHashMap = Corpus.getSpanMap(article, featureType);
			trees = Corpus.getTrees(article, featureType);
			explicitSpans = Corpus.getExplicitSpans(article, featureType);

			if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
				explicitSpans = Corpus.filterErrorProp(explicitSpans, article, featureType);
			}
		} else {
			spanMap = Corpus.getBioSpanMapAsList(article, featureType);
			spanHashMap = Corpus.getBioSpanMap(article, featureType);
			trees = Corpus.getBioTrees(article, featureType);
			explicitSpans = Corpus.getBioExplicitSpans(article, featureType);
			if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
				explicitSpans = Corpus.filterBioErrorProp(explicitSpans, article, featureType);
			}
		}

		int index = 0;
		int contIndex = 0;

		for (String rel : explicitSpans) {
			String[] cols = rel.split("\\|", -1);
			index = contIndex;
			List<Node> nodes = new ArrayList<>();
			Tree root = null;

			String[] spans = cols[corpus.equals(Type.PDTB) ? 3 : 1].split(";");

			for (String spanTmp : spans) {
				String[] span = spanTmp.split("\\.\\.");

				for (; index < spanMap.size(); ++index) {
					// wsj_1371,0,6,9..21,Shareholders
					String line = spanMap.get(index);
					String[] spanCols = line.split(",");
					String[] canSpan = spanCols[3].split("\\.\\.");

					// Start matches
					if (span[0].equals(canSpan[0]) || nodes.size() > 0) {
						if (nodes.size() == 0) {
							contIndex = index;
						}
						root = trees.get(Integer.parseInt(spanCols[1]));
						List<Tree> leaves = root.getLeaves();
						int start = Integer.parseInt(spanCols[2]);
						Tree node = root.getNodeNumber(start);
						int nodeNum = 0;

						for (; nodeNum < leaves.size(); ++nodeNum) {
							Tree potNode = leaves.get(nodeNum);
							if (node.equals(potNode)) {
								int tmp = potNode.nodeNumber(root);
								String tmpSpan = spanHashMap.get(spanCols[1] + ":" + tmp);
								if (tmpSpan.equals(spanCols[3])) {
									break;
								}
							}
						}

						nodes.add(new Node(node, nodeNum));

						if (span[1].equals(canSpan[1])) {
							break;
						}
					}
				}
			}

			if (!nodes.isEmpty()) {
				Set<String> semantics = Util.getUniqueSense(new String[] { cols[corpus.equals(Type.PDTB) ? 11 : 8],
						cols[corpus.equals(Type.PDTB) ? 12 : 9] });
				String sem = "";
				if (featureType == FeatureType.Training) {
					for (String sm : semantics) {
						sm = sm.replace(' ', '_');
						String feature = printFeature(root, nodes, sm);
						features.add(new String[] { feature });
					}
				} else {
					if (featureType == FeatureType.AnyText) {
						semantics.add("xxx");
					}
					for (String e : semantics) {
						sem += e.replace(' ', '_');
						sem += "£";
					}
					String feature = printFeature(root, nodes, sem);
					features.add(new String[] { feature, rel });
				}
			}
		}

		return features;
	}

	private String printFeature(Tree root, List<Node> nodes, String label) {

		StringBuilder feature = new StringBuilder();

		StringBuilder tmp = new StringBuilder();
		StringBuilder tmp2 = new StringBuilder();
		for (Node node : nodes) {
			if (node.tree.parent(root) != null) {
				tmp.append(node.tree.parent(root).value() + " ");
				tmp2.append(node.tree.value() + " ");
			}
		}
		String POS = tmp.toString().trim().replace(' ', '_');
		String connStr = tmp2.toString().trim().replace(' ', '_');
		if (connStr.equalsIgnoreCase("if_then") || connStr.equalsIgnoreCase("either_or")
				|| connStr.equalsIgnoreCase("neither..nor")) {
			connStr = connStr.replaceAll("_", "..");
		}
		List<Tree> leaves = root.getLeaves();

		int firstNodeNum = nodes.get(0).index;

		Tree prevNode = firstNodeNum > 0 ? leaves.get(--firstNodeNum) : null;

		feature.append("conn_lc:");
		feature.append(connStr.toLowerCase());
		feature.append(' ');

		feature.append("conn:");
		feature.append(connStr);
		feature.append(' ');

		feature.append("conn_POS:");
		feature.append(POS);
		feature.append(' ');

		if (prevNode != null) {
			while (prevNode.parent(root).value().equals("-NONE-") && firstNodeNum > 0) {
				prevNode = leaves.get(--firstNodeNum);
			}

			if (prevNode != null) {

				feature.append("with_prev_full:");
				feature.append(prevNode.value().replace(' ', '_').toLowerCase());
				feature.append('_');
				feature.append(connStr.toLowerCase());
				feature.append(' ');

			}
		}

		feature.append(label.replace(' ', '_'));

		return feature.toString().replaceAll("/", "\\\\/");
	}

	@Override
	public File parseAnyText(File modelFile, File inputFile) throws IOException {
		String filePath = OUTPUT_FOLDER_NAME + inputFile.getName() + "." + NAME;
		File testFile = new File(filePath);
		PrintWriter featureFile = new PrintWriter(testFile);
		List<String[]> features = generateFeatures(inputFile, FeatureType.AnyText);
		for (String[] feature : features) {
			featureFile.println(feature[0]);
		}
		featureFile.close();
		File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(filePath + ".out"));

		File resultFile = new File(filePath + ".res");
		PrintWriter pw = new PrintWriter(resultFile);
		try (BufferedReader read = Util.reader(outFile)) {
			for (String[] feature : features) {
				String[] tmp = read.readLine().split("\\s+");
				String[] cols = feature[1].split("\\|", -1);
				String fullSense = Corpus.getFullSense(tmp[tmp.length - 1]);
				pw.println(cols[3] + "|" + fullSense);
			}
		}
		pw.close();

		return resultFile;
	}

	public File trainBioDrb() throws IOException {

		FeatureType featureType = FeatureType.Training;

		String name = this.name + featureType.toString();

		File trainFile = new File(MODEL_PATH + name);
		PrintWriter featureFile = new PrintWriter(trainFile);

		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".txt");
			}
		});

		File auxFile = new File(name + ".aux");
		PrintWriter auxFileWriter = new PrintWriter(auxFile);

		for (File file : files) {
			if (TestBioDrb.trainSet.contains(file.getName())) {
				log.trace("Article: " + file.getName());

				List<String[]> features = generateFeatures(Type.BIO_DRB, file, featureType);

				for (String[] feature : features) {
					featureFile.println(feature[0]);
					if (feature.length > 1) {
						auxFileWriter.println(feature[1]);
					}
				}
				featureFile.flush();
			}
		}
		auxFileWriter.close();
		featureFile.close();

		File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);

		return modelFile;
	}

	public File testBioDrb(FeatureType featureType) throws IOException {
		String name = NAME + featureType.toString();
		File testFile = new File(MODEL_PATH + name);
		PrintWriter featureFile = new PrintWriter(testFile);
		String dir = MODEL_PATH + name.replace('.', '_') + "/";
		new File(dir).mkdirs();

		log.info("Printing " + featureType + " features: ");
		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith("txt");
			}
		});

		for (File file : files) {
			if (TestBioDrb.testSet.contains(file.getName())) {
				log.trace("Article: " + file.getName());

				String articleName = dir + file.getName();

				File articleTest = new File(articleName + ".features");
				PrintWriter articleFeatures = new PrintWriter(articleTest);

				File auxFile = new File(articleName + ".aux");
				PrintWriter auxFileWriter = new PrintWriter(auxFile);

				List<String[]> features = generateFeatures(Type.BIO_DRB, file, featureType);
				for (String[] feature : features) {
					featureFile.println(feature[0]);
					articleFeatures.println(feature[0]);
					String headSpan = feature[1].split("\\|", -1)[1];
					auxFileWriter.println(headSpan);

				}
				featureFile.flush();
				articleFeatures.close();
				auxFileWriter.close();

				File articleOut = MaxEntClassifier.predict(articleTest, modelFile, new File(articleName + ".out"));
				String pipeDir = MODEL_PATH + "pipes" + featureType.toString().replace('.', '_');
				new File(pipeDir).mkdirs();
				makeExpBioPipeFile(pipeDir, articleOut, auxFile, file.getName());
			}
		}
		featureFile.close();

		File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(Settings.MODEL_PATH + name + ".out"));

		return outFile;
	}

	private void makeExpBioPipeFile(String pipeDir, File articleOut, File auxFile, String article) throws IOException {
		Map<String, String> spanToPipe = new HashMap<>();
		File pipeFile = new File(pipeDir + "/" + article + ".pipe");
		String[] pipes = Util.readFile(pipeFile).split(Util.NEW_LINE);
		for (String pipe : pipes) {
			String[] cols = pipe.split("\\|", -1);
			spanToPipe.put(cols[1], pipe);
		}
		if (spanToPipe.size() > 0) {
			PrintWriter pipeWriter = new PrintWriter(pipeFile);
			try (BufferedReader reader = Util.reader(auxFile)) {
				try (BufferedReader outReader = Util.reader(articleOut)) {
					String span;
					while ((span = reader.readLine()) != null) {
						String[] out = outReader.readLine().split("\\s+");
						String sense = out[out.length - 1];
						String[] cols = spanToPipe.get(span).split("\\|", -1);
						StringBuilder newPipe = new StringBuilder();

						for (int i = 0; i < cols.length; ++i) {
							if (i == 8) {
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
		} else {
			log.warn("Article:" + article + " has no pipes!");
		}
	}

}
