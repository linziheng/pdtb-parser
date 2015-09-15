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

import static sg.edu.nus.comp.pdtb.util.Settings.TMP_PATH;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.model.Node;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Util;
import edu.stanford.nlp.trees.Tree;

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
		List<String[]> features = new ArrayList<>();
		ArrayList<String> spanMap = Corpus.getSpanMapAsList(article, featureType);
		Map<String, String> spanHashMap = Corpus.getSpanMap(article, featureType);
		List<Tree> trees = Corpus.getTrees(article, featureType);

		List<String> explicitSpans = Corpus.getExplicitSpans(article, featureType);

		if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
			explicitSpans = Corpus.filterErrorProp(explicitSpans, article, featureType);
		}

		int index = 0;
		int contIndex = 0;

		for (String rel : explicitSpans) {
			String[] cols = rel.split("\\|", -1);
			index = contIndex;
			List<Node> nodes = new ArrayList<>();
			Tree root = null;

			String[] spans = cols[3].split(";");

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
				Set<String> semantics = Util.getUniqueSense(new String[] { cols[11], cols[12] });
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
			tmp.append(node.tree.parent(root).value() + " ");
			tmp2.append(node.tree.value() + " ");
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
		String filePath = TMP_PATH + inputFile.getName() + "." + NAME;
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

}
