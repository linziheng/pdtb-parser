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
import java.io.FileInputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Set;

import edu.stanford.nlp.trees.Tree;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.model.Node;
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
public class ArgExtComp extends Component {

	public static final String NAME = "argext";

	private int majorIndex = 0;
	private int doneSoFar = 0;
	private List<String> labels;
	private List<Tree> trees;
	private Map<String, String> sentMap;
	private String orgText;

	public ArgExtComp() {
		super(NAME, ArgExtComp.class.getName());
	}

	@Override
	public File train() throws IOException {
		File trainFile = new File(MODEL_PATH + name + FeatureType.Training);
		PrintWriter featureFile = new PrintWriter(trainFile);
		log.info("Training:");

		for (int section : Settings.TRAIN_SECTIONS) {
			log.info("Section: " + section);
			File[] files = Corpus.getSectionFiles(section);

			for (File article : files) {
				log.trace("Article: " + article.getName());

				List<String[]> features = generateFeatures(article, FeatureType.Training);
				doneSoFar += features.size();

				for (String[] feature : features) {
					featureFile.println(feature[0]);
				}

				featureFile.flush();
			}
		}
		featureFile.close();

		File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);
		return modelFile;
	};

	public File trainBioDrb(Set<String> trainSet) throws IOException {
		File trainFile = new File(MODEL_PATH + name + FeatureType.Training);
		PrintWriter featureFile = new PrintWriter(trainFile);
		log.info("Training:");
		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".txt");
			}
		});

		for (File article : files) {
			if (trainSet.contains(article.getName())) {
				log.trace("Article: " + article.getName());

				List<String[]> features = generateFeatures(Type.BIO_DRB, article, FeatureType.Training);
				doneSoFar += features.size();

				for (String[] feature : features) {
					featureFile.println(feature[0]);
				}

				featureFile.flush();
			}
		}
		featureFile.close();

		File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);
		return modelFile;
	}

	@Override
	public File getGsFile(FeatureType featureType) {
		String name = NAME + featureType.toString();
		return new File(MODEL_PATH + name + ".pipe");
	}

	@Override
	public File parseAnyText(File modelFile, File inputFile) throws IOException {
		String name = OUTPUT_FOLDER_NAME + inputFile.getName() + "." + NAME;
		File featureFile = new File(name);
		File auxFile = new File(name + ".aux");
		File outFile = new File(name + ".out");

		PrintWriter featureWriter = new PrintWriter(featureFile);

		PrintWriter auxWriter = new PrintWriter(auxFile);

		labels = getArgPosLabels(inputFile, FeatureType.AnyText);
		orgText = Util.readFile(inputFile);
		orgText = orgText.replaceAll("`", "'");

		majorIndex = 0;
		List<String[]> features = generateFeatures(inputFile, FeatureType.AnyText);
		for (String[] feature : features) {
			featureWriter.println(feature[0]);
			auxWriter.println(feature[2]);
		}

		featureWriter.close();
		auxWriter.close();

		MaxEntClassifier.predict(featureFile, modelFile, outFile);

		File pipeFile = new File(OUTPUT_FOLDER_NAME + inputFile.getName() + ".pipe");
		PrintWriter pipeWriter = new PrintWriter(pipeFile);

		printAnyTxtPsArgs(pipeWriter, inputFile);
		printAnyTxtSsArgs(pipeWriter, inputFile);

		pipeWriter.close();

		return pipeFile;
	}

	private void printAnyTxtSsArgs(PrintWriter pipeWriter, File inputFile) throws IOException {
		String name = OUTPUT_FOLDER_NAME + inputFile.getName() + "." + NAME;
		List<String> explicitSpans = Corpus.getExplicitSpans(inputFile, FeatureType.AnyText);
		Map<String, String> pipeHash = new HashMap<>();
		for (String pipe : explicitSpans) {
			String[] cols = pipe.split("\\|", -1);
			pipeHash.put(cols[3], pipe);
		}

		try (BufferedReader er = Util.reader(name + ".aux");
				BufferedReader prd = Util.reader(name + ".out");
				BufferedReader tst = Util.reader(name)) {
			String tmp;
			while ((tmp = er.readLine()) != null) {
				String[] line = tmp.split(":");
				Map<String, String> spanHashMap = Corpus.getSpanMap(inputFile, FeatureType.AnyText);
				String[] index = line[1].split("\\-");
				int stIndex = Integer.parseInt(index[0]);
				int endIndex = Integer.parseInt(index[1]);
				List<String> arg1Nodes = new ArrayList<>();
				List<String> arg2Nodes = new ArrayList<>();
				double arg1Max = 0, arg2Max = 0;
				int arg1Ind = 0;

				String[] nodes = new String[endIndex - stIndex];
				String[][] vals = new String[endIndex - stIndex][];

				for (int i = stIndex; i < endIndex; ++i) {
					tmp = prd.readLine();
					tmp = tmp.replace(',', '.');
					vals[i - stIndex] = tmp.split("\\s+");
					tmp = tst.readLine();
					nodes[i - stIndex] = tmp.substring(tmp.lastIndexOf(' ')).trim();

					if (i + 1 < endIndex) {
						tmp = er.readLine();
						if (tmp == null) {
							tmp = null;
							log.error("out");
							break;
						}
					}
				}

				for (int i = 0; i < nodes.length; ++i) {
					double val = Double
							.parseDouble(vals[i][1].substring(vals[i][1].indexOf('[') + 1, vals[i][1].indexOf(']')));
					if (val > arg1Max) {
						arg1Ind = i;
						arg1Nodes.clear();
						arg1Nodes.add(nodes[i]);
						arg1Max = val;
					}
				}

				for (int i = 0; i < nodes.length; ++i) {
					double val = Double
							.parseDouble(vals[i][2].substring(vals[i][2].indexOf('[') + 1, vals[i][2].indexOf(']')));
					if (val > arg2Max && arg1Ind != i) {
						arg2Nodes.clear();
						arg2Nodes.add(nodes[i]);
						arg2Max = val;
					}
				}

				String arg2Span = calcNodesSpan(arg2Nodes, spanHashMap, line[4], null);
				String arg1Span = calcNodesSpan(arg1Nodes, spanHashMap, line[4], arg2Nodes);
				String arg2Txt = Corpus.spanToText(arg2Span, orgText).replaceAll("\\|", "<PIPE>");
				String arg1Txt = Corpus.spanToText(arg1Span, orgText).replaceAll("\\|", "<PIPE>");

				String[] cols = pipeHash.get(line[4]).split("\\|", -1);

				StringBuilder resultLine = new StringBuilder();

				int sentNumber = -1;
				for (int i = 0; i < cols.length; i++) {
					String col = cols[i];
					if (i == 7) {
						sentNumber = Integer.parseInt(col);
					}
					if (i == 22) {
						resultLine.append(arg1Span + "|");
					} else if (i == 23) {
						resultLine.append(sentNumber + "|");
					} else if (i == 24) {
						resultLine.append(arg1Txt + "|");

					} else if (i == 32) {
						resultLine.append(arg2Span + "|");
					} else if (i == 33) {
						resultLine.append(sentNumber + "|");
					} else if (i == 34) {
						resultLine.append(arg2Txt + "|");
					} else {
						resultLine.append(col + "|");
					}
				}
				resultLine.deleteCharAt(resultLine.length() - 1);

				pipeWriter.println(resultLine.toString());
				pipeWriter.flush();
			}
		}
	}

	private void printAnyTxtPsArgs(PrintWriter pipeWriter, File inputFile) throws IOException {
		majorIndex = 0;
		List<String> explicitSpans = Corpus.getExplicitSpans(inputFile, FeatureType.AnyText);
		Map<String, String> spanHashMap = Corpus.getSpanMap(inputFile, FeatureType.AnyText);
		for (String rel : explicitSpans) {
			String label = labels.get(majorIndex);
			majorIndex++;
			if (label.equals("PS")) {
				String[] cols = rel.split("\\|", -1);
				String[] args = getAnyPSArgSpans(rel, spanHashMap);

				StringBuilder resultLine = new StringBuilder();
				int sentNumber = -1;
				for (int i = 0; i < cols.length; i++) {
					String col = cols[i];
					if (i == 7) {
						sentNumber = Integer.parseInt(col);
					}

					if (i == 22) {
						resultLine.append(args[0] + "|");
					} else if (i == 23) {
						resultLine.append((sentNumber - 1) + "|");
					} else if (i == 24) {
						resultLine.append(args[2] + "|");

					} else if (i == 32) {
						resultLine.append(args[1] + "|");
					} else if (i == 33) {
						resultLine.append(sentNumber + "|");
					} else if (i == 34) {
						resultLine.append(args[3] + "|");
					} else {
						resultLine.append(col + "|");
					}
				}
				resultLine.deleteCharAt(resultLine.length() - 1);

				pipeWriter.println(resultLine.toString());
				pipeWriter.flush();
			}
		}
	}

	private String[] getAnyPSArgSpans(String pipe, Map<String, String> spanHashMap) {
		String[] cols = pipe.split("\\|", -1);
		String connSpan = cols[3];
		int arg2TreeNum = Integer.parseInt(cols[7]);

		Tree arg2Root = trees.get(arg2TreeNum);
		String arg2 = (arg2TreeNum) + ":" + arg2Root.firstChild().nodeNumber(arg2Root);
		ArrayList<String> arg2Nodes = new ArrayList<String>();
		arg2Nodes.add(arg2);

		String arg2Span = calcNodesSpan(arg2Nodes, spanHashMap, connSpan, null);
		String arg1Span = "1..2";

		if (arg2TreeNum > 0) {
			int arg1TreeNum = arg2TreeNum - 1;
			Tree arg1Root = trees.get(arg1TreeNum);
			String arg1 = (arg1TreeNum) + ":" + arg1Root.firstChild().nodeNumber(arg1Root);
			ArrayList<String> arg1Nodes = new ArrayList<String>();
			arg1Nodes.add(arg1);
			arg1Span = calcNodesSpan(arg1Nodes, spanHashMap, connSpan, arg2Nodes);
		}

		return new String[] { arg1Span, arg2Span, Corpus.spanToText(arg1Span, orgText).replaceAll("\\|", "<PIPE>"),
				Corpus.spanToText(arg2Span, orgText).replaceAll("\\|", "<PIPE>") };
	}

	@Override
	public File test(File model, FeatureType featureType) throws IOException {

		String name = NAME + featureType.toString();
		File featureFile = new File(MODEL_PATH + name);
		File pipeFile = new File(MODEL_PATH + name + ".pipe");
		File auxFile = new File(MODEL_PATH + name + ".aux");

		PrintWriter featureWriter = new PrintWriter(featureFile);
		PrintWriter pipeWriter = new PrintWriter(pipeFile);
		PrintWriter auxWriter = new PrintWriter(auxFile);

		labels = getArgPosLabels(featureType);
		majorIndex = 0;

		log.info("Printing " + featureType + " features: ");
		for (int section : Settings.TEST_SECTIONS) {
			log.info("Section: " + section);
			File[] files = Corpus.getSectionFiles(section);
			for (File file : files) {
				log.trace("Article: " + file.getName());
				List<String[]> features = generateFeatures(file, featureType);
				for (String[] feature : features) {
					featureWriter.println(feature[0]);
					pipeWriter.println(feature[1]);
					auxWriter.println(feature[2]);
				}
				featureWriter.flush();
				pipeWriter.flush();
				auxWriter.flush();
			}
		}
		featureWriter.close();
		pipeWriter.close();
		auxWriter.close();

		MaxEntClassifier.predict(featureFile, modelFile, new File(MODEL_PATH + name + ".out"));
		File outFile = generateArguments(featureType);

		String pipeDir = MODEL_PATH + "pipes" + featureType.toString().replace('.', '_');
		new File(pipeDir).mkdirs();
		makePipeFile(pipeDir, outFile);

		return outFile;
	};

	public File testBioDrb(Set<String> testSet, FeatureType featureType) throws IOException {
		String name = NAME + featureType.toString();
		File featureFile = new File(MODEL_PATH + name);
		File pipeFile = new File(MODEL_PATH + name + ".pipe");
		File auxFile = new File(MODEL_PATH + name + ".aux");

		PrintWriter featureWriter = new PrintWriter(featureFile);
		PrintWriter pipeWriter = new PrintWriter(pipeFile);
		PrintWriter auxWriter = new PrintWriter(auxFile);

		labels = getArgPosLabels(featureType);
		majorIndex = 0;

		log.info("Testing: ");
		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".txt");
			}
		});

		for (File article : files) {
			if (testSet.contains(article.getName())) {
				log.trace("Article: " + article.getName());
				List<String[]> features = generateFeatures(Type.BIO_DRB, article, featureType);
				for (String[] feature : features) {
					featureWriter.println(feature[0]);
					pipeWriter.println(feature[1]);
					auxWriter.println(feature[2]);
				}
				featureWriter.flush();
				pipeWriter.flush();
				auxWriter.flush();
			}
		}
		featureWriter.close();
		pipeWriter.close();
		auxWriter.close();

		MaxEntClassifier.predict(featureFile, modelFile, new File(MODEL_PATH + name + ".out"));
		log.info("Generating arguments");
		File outFile = generateArguments(Type.BIO_DRB, featureType);

		String pipeDir = MODEL_PATH + "pipes" + featureType.toString().replace('.', '_');
		new File(pipeDir).mkdirs();
		makeBioPipeFile(pipeDir, outFile);
		return outFile;
	}

	private List<String> getArgPosLabels(FeatureType featureType) throws IOException {
		return getArgPosLabels(null, featureType);
	}

	private List<String> getArgPosLabels(File inputFile, FeatureType featureType) throws IOException {

		String path = "";

		if (featureType == FeatureType.AnyText) {
			path = Settings.OUTPUT_FOLDER_NAME + inputFile.getName() + "." + ArgPosComp.NAME + ".out";
		} else {
			path = Settings.MODEL_PATH + ArgPosComp.NAME + featureType + ".out";
		}

		List<String> list = new ArrayList<>();

		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(path), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] tmp = line.split("\\s+");
				list.add(tmp[tmp.length - 1]);
			}
		}

		return list;
	}

	@Override
	public List<String[]> generateFeatures(File article, FeatureType featureType) throws IOException {
		return generateFeatures(Type.PDTB, article, featureType);
	}

	public List<String[]> generateFeatures(Type corpus, File article, FeatureType featureType) throws IOException {
		List<String[]> features = new ArrayList<>();

		ArrayList<String> spanArray = null;
		Map<String, String> spanHashMap = null;
		List<String> explicitSpans = null;

		if (corpus.equals(Type.PDTB)) {
			spanArray = Corpus.getSpanMapAsList(article, featureType);
			spanHashMap = Corpus.getSpanMap(article, featureType);
			trees = Corpus.getTrees(article, featureType);
			explicitSpans = Corpus.getExplicitSpans(article, featureType);

			if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
				explicitSpans = Corpus.filterErrorProp(explicitSpans, article, featureType);
			}

			if (featureType == FeatureType.Auto) {
				sentMap = Corpus.getSentMap(article);
			}
		} else {
			spanArray = Corpus.getBioSpanMapAsList(article, featureType);
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

			String argPos = null;
			if (corpus == Type.PDTB) {
				if (featureType == FeatureType.Training) {
					argPos = Corpus.getLabel(cols[23], cols[33]);
				} else {
					argPos = labels.get(majorIndex);
				}
			} else {
				argPos = Corpus.getBioLabel(cols[14], cols[20], spanArray);
			}

			if (argPos.equals("FS")) {
				continue;
			}

			if (featureType != FeatureType.Training) {
				argPos = labels.get(majorIndex);
			}
			++majorIndex;

			if (argPos.equals("SS")) {
				Set<Integer> done = new HashSet<>();

				index = contIndex;
				List<Node> nodes = new ArrayList<>();
				Tree root = null;

				String[] spans = corpus.equals(Type.PDTB) ? cols[3].split(";") : cols[1].split(";");

				for (String spanTmp : spans) {
					String[] span = spanTmp.split("\\.\\.");

					for (; index < spanArray.size(); ++index) {
						// wsj_1371,0,6,9..21,Shareholders
						String line = spanArray.get(index);
						String[] spanCols = line.split(",");
						String[] canSpan = spanCols[3].split("\\.\\.");
						// Start matches
						// if (span[0].equals(canSpan[0]) || nodes.size() > 0) {
						boolean flag = span[0].equals(canSpan[0]) || (nodes.size() > 0 && spans.length == 1
								&& Integer.parseInt(canSpan[1]) <= Integer.parseInt(span[1]));
						if (corpus.equals(Type.BIO_DRB)) {
							int start = Integer.parseInt(canSpan[0]);
							int end = Integer.parseInt(canSpan[1]);
							int outStart = Integer.parseInt(span[0]);
							int outEnd = Integer.parseInt(span[1]);

							flag = outStart <= start && end <= outEnd;
						}
						if (flag) {
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
							if (!done.contains(nodeNum)) {
								done.add(nodeNum);
								nodes.add(new Node(node, nodeNum));
							}
							if (span[1].equals(canSpan[1])) {
								++index;
								break;
							}
						}
					}
				}
				if (!nodes.isEmpty()) {
					String connStr = null;
					String connCat = null;

					if (corpus.equals(Type.PDTB)) {
						connStr = cols[8].trim().replace(' ', '_');
						String c = cols[5].substring(0, 1);
						if (c.toLowerCase().equals(connStr.substring(0, 1))) {
							connStr = c + connStr.substring(1);
						}

						connCat = ConnComp.findCategory(cols[8]);
					} else {
						StringBuilder tmp = new StringBuilder();
						for (Node node : nodes) {
							tmp.append(node.tree + " ");
						}
						connStr = tmp.toString();
						connStr = connStr.trim().toLowerCase().replace(' ', '_');
						connCat = ConnComp.findCategory(connStr.replace('_', ' '), corpus);
					}

					Tree connNode = nodes.get(nodes.size() - 1).tree.parent(root);

					Tree[] argNodes = corpus.equals(Type.PDTB) ? getArgNodes(root, cols, spanArray, connCat, connNode)
							: getBioArgNodes(root, cols, spanArray, connCat, connNode);
					List<Tree> internal = getInternalNodes(root, root);

					String treeNum;
					String line;
					int total = (doneSoFar + features.size());
					if (corpus.equals(Type.PDTB)) {
						treeNum = featureType == FeatureType.AnyText ? cols[7] : getNodeNum(cols[23], featureType);
						line = article.getName() + ":" + total + "-" + (total + internal.size()) + ":Arg1(" + cols[22]
								+ "):Arg2(" + cols[32] + "):" + cols[3];

					} else {
						treeNum = Corpus.spanToSenIds(cols[14], spanArray).getFirst().toString();
						line = article.getName() + ":" + total + "-" + (total + internal.size()) + ":Arg1(" + cols[14]
								+ "):Arg2(" + cols[20] + "):" + cols[1];
					}

					for (Tree node : internal) {
						String label = "";
						if (node.equals(argNodes[0])) {
							label = "arg1_node";
						} else if (node.equals(argNodes[1])) {
							label = "arg2_node";
						} else {
							label = "none";
						}

						if (featureType != FeatureType.Training) {
							label = treeNum + ":" + node.nodeNumber(root);
						}
						String feature = printFeature(root, node, connStr, connCat, connNode, label);
						features.add(new String[] { feature, rel, line });
					}
				}
			}
		}

		return features;
	}

	private String printFeature(Tree root, Tree node, String connStr, String connCat, Tree connNode, String label) {
		StringBuilder feature = new StringBuilder();

		feature.append("conn:");
		feature.append(connStr);
		feature.append(' ');

		feature.append("conn_lc:");
		feature.append(connStr.toLowerCase());
		feature.append(' ');

		feature.append("conn_cat:");
		feature.append(connCat);
		feature.append(' ');

		String path = findPath(root, connNode, node);
		feature.append("conn_to_node:");
		feature.append(path);
		feature.append(' ');

		Tree parent = connNode.parent(root);
		Tree[] children = parent.children();

		int lsibs = 0;
		int rsibs = 0;
		boolean countLeft = true;
		for (int i = 0; i < children.length; ++i) {
			if (children[i].equals(connNode)) {
				countLeft = false;
				continue;
			}
			if (countLeft) {
				++lsibs;
			} else {
				++rsibs;
			}
		}

		feature.append("conn_node_lsib_size=");
		feature.append(lsibs);
		feature.append(' ');

		feature.append("conn_node_rsib_size=");
		feature.append(rsibs);
		feature.append(' ');
		if (lsibs > 1) {
			feature.append("conn_to_node:");
			feature.append(path);
			feature.append("^conn_node_lsib_size:>1");
			feature.append(' ');
		}

		int relpos = relativePosition(root, connNode, node);
		feature.append("conn_to_node_relpos:");
		feature.append(relpos);
		feature.append(' ');

		feature.append(label);

		return feature.toString();
	}

	/**
	 * <pre>
	 *     # 0:  node1 and node2 in the same path to root
	 *     # 1:  node2 is at the rhs of node1's path to root
	 *     # -1: node2 is at the lhs of node1's path to root
	 * </pre>
	 * 
	 * @param root
	 * @param connNode
	 * @param node
	 * @return
	 */
	private static int relativePosition(Tree root, Tree connNode, Tree node) {
		Tree curr = connNode;
		while (curr != null && !curr.equals(root)) {
			if (curr.equals(node)) {
				return 0;
			}
			Tree parent = curr.parent(root);
			Tree[] children = parent.children();

			for (int i = 0; i < children.length; ++i) {
				if (children[i].contains(node)) {
					int nodeNum = node.nodeNumber(root);
					int connNum = connNode.nodeNumber(root);

					if (nodeNum < connNum) {
						return -1;
					} else {
						return 1;
					}
				}
			}

			curr = parent;
		}

		return 0;
	}

	private String findPath(Tree root, Tree connNode, Tree node) {
		Tree lca = getLCA(root, connNode, node);

		List<String> n1ToLca = findUpwardPath(root, connNode, lca);
		List<String> n2ToLca = findUpwardPath(root, node, lca);

		if (!n2ToLca.isEmpty() && n2ToLca.get(n2ToLca.size() - 1) != null && !n1ToLca.isEmpty()
				&& n1ToLca.get(n1ToLca.size() - 1).equals(n2ToLca.get(n2ToLca.size() - 1))) {
			n2ToLca.remove(n2ToLca.size() - 1);
		}

		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < n1ToLca.size(); ++i) {
			sb.append(n1ToLca.get(i));
			if (i < n1ToLca.size() - 1) {
				sb.append("->");
			}
		}

		for (int i = n2ToLca.size() - 1; i > -1; --i) {
			sb.append("<-");
			sb.append(n2ToLca.get(i));
		}

		return sb.toString();
	}

	private static Tree getLCA(Tree root, Tree connNode, Tree node) {
		List<Tree> nodes = new ArrayList<>();
		nodes.add(connNode);
		nodes.add(node);

		return getLCA(root, nodes);
	}

	private static List<String> findUpwardPath(Tree root, Tree connNode, Tree lca) {
		List<String> path = new ArrayList<>();
		if (connNode == null || lca == null) {// || connNode.equals(lca)) {
			return path;
		}

		Tree curr = connNode;
		while (curr != null && !curr.equals(lca)) {
			String val = curr.value();
			if (val != null) {
				int t = val.indexOf("-");
				if (t > 0) {
					val = val.substring(0, t);
				}
				path.add(val);
			}
			curr = curr.parent(root);
		}

		if (curr != null && curr.equals(lca)) {
			String val = curr.value();
			if (val != null) {
				int t = val.indexOf("-");
				if (t > 0) {
					val = val.substring(0, t);
				}
				path.add(val);
			}
		}

		if (curr == null && path.isEmpty()) {
			return new ArrayList<>();
		} else {
			return path;
		}
	}

	private int getNodeNum(int connTree, FeatureType featureType) {
		return Integer.parseInt(getNodeNum(Integer.toString(connTree), featureType));
	}

	private String getNodeNum(String nodeNum, FeatureType featureType) {
		String result = nodeNum.split(";")[0].split(",")[0];
		if (featureType == FeatureType.Auto) {
			if (sentMap.containsKey(result)) {
				result = sentMap.get(result);
			} else {
				log.error("SentMap don't contain nodenumber" + nodeNum);
			}
		}
		return result;
	}

	private Tree[] getBioArgNodes(Tree root, String[] cols, ArrayList<String> spanArray, String connCat,
			Tree connNode) {
		List<Tree> arg1Nodes = getTreeNodesFromSpan(cols[14], spanArray);

		if (connCat.equals("Coordinator") && connNode.value().equals("CC")) {
			Tree[] children = connNode.parent(root).children();
			for (Tree child : children) {
				int ind = arg1Nodes.indexOf(child);
				if (ind == -1 && isPuncTag(child.value())) {
					arg1Nodes.add(child);
				}
			}
		}

		Tree arg1Node = (arg1Nodes.size() == 1) ? arg1Nodes.get(0) : getLCA(root, arg1Nodes);

		List<Tree> arg2Nodes = getTreeNodesFromSpan(cols[20], spanArray);

		Tree arg2Node = (arg2Nodes.size() == 1) ? arg2Nodes.get(0) : getLCA(root, arg2Nodes);

		return new Tree[] { arg1Node, arg2Node };
	}

	private Tree[] getArgNodes(Tree root, String[] cols, ArrayList<String> spanArray, String connCat, Tree connNode) {
		List<Tree> arg1Nodes = getTreeNodesFromSpan(cols[22], spanArray);
		arg1Nodes.addAll(getTreeNodesFromSpan(cols[29], spanArray));

		if (connCat.equals("Coordinator") && connNode.value().equals("CC")) {
			Tree[] children = connNode.parent(root).children();
			for (Tree child : children) {
				int ind = arg1Nodes.indexOf(child);
				if (ind == -1 && isPuncTag(child.value())) {
					arg1Nodes.add(child);
				}
			}
		}

		Tree arg1Node = (arg1Nodes.size() == 1) ? arg1Nodes.get(0) : getLCA(root, arg1Nodes);

		List<Tree> arg2Nodes = getTreeNodesFromSpan(cols[32], spanArray);
		arg2Nodes.addAll(getTreeNodesFromSpan(cols[39], spanArray));

		Tree arg2Node = (arg2Nodes.size() == 1) ? arg2Nodes.get(0) : getLCA(root, arg2Nodes);

		return new Tree[] { arg1Node, arg2Node };
	}

	private List<Tree> getTreeNodesFromSpan(String column, ArrayList<String> spanArray) {
		List<Tree> nodes = new ArrayList<>();
		if (column.isEmpty()) {
			return nodes;
		}
		String[] spans = column.split(";");
		for (String span : spans) {
			if (span.length() > 0) {
				String[] tmp = span.split("\\.\\.");
				int begin = Integer.parseInt(tmp[0]);
				int end = Integer.parseInt(tmp[1]);
				for (String line : spanArray) {
					// wsj_1371,0,6,9..21,Shareholders
					String[] tt = line.split(",");
					tmp = tt[3].split("\\.\\.");
					int b = Integer.parseInt(tmp[0]);
					int e = Integer.parseInt(tmp[1]);
					if (begin <= b && e <= end) {
						int nodeNum = Integer.parseInt(tt[2]);
						int treeNum = Integer.parseInt(tt[1]);
						nodes.add(trees.get(treeNum).getNodeNumber(nodeNum));
					}
				}
			}
		}

		return nodes;
	}

	private static boolean isPuncTag(String value) {

		for (String punc : ConnComp.PUNC_TAGS) {
			if (punc.equals(value)) {
				return true;
			}
		}
		return false;
	}

	public static Tree getLCA(Tree root, List<Tree> nodes) {

		Tree lca = null;
		Queue<Tree> queue = new LinkedList<>();
		queue.add(root);

		while (queue.size() > 0) {
			Tree curr = queue.remove();
			Set<Tree> allNodes = getAllNodes(curr);
			boolean contains = true;

			for (Tree node : nodes) {
				contains &= allNodes.contains(node);
				if (!contains) {
					break;
				}
			}

			if (contains) {
				lca = curr;
				Tree[] children = curr.children();
				for (Tree child : children) {
					queue.add(child);
				}
			}
		}

		return lca;
	}

	private static Set<Tree> getAllNodes(Tree curr) {
		Set<Tree> set = new HashSet<>();

		if (curr != null) {
			set.add(curr);
			Tree[] children = curr.children();
			for (Tree child : children) {
				set.addAll(getAllNodes(child));
			}
		}

		return set;
	}

	private static List<Tree> getInternalNodes(Tree root, Tree node) {
		// @child_nodes.size == 1 and @child_nodes.first.class != Node

		List<Tree> result = new ArrayList<>();

		if (node != null && !(node.children().length == 1 && node.firstChild() != null && node.firstChild().isLeaf())) {
			Tree parent = node.parent(root);
			if (parent != null && !node.value().equals("-NONE-")) {
				result.add(node);
			}
			Tree[] children = node.children();
			for (Tree child : children) {
				result.addAll(getInternalNodes(root, child));
			}
		}

		return result;
	}

	private File generateArguments(FeatureType featureType) throws IOException {
		return generateArguments(Type.PDTB, featureType);
	}

	public File generateArguments(Type corpus, FeatureType featureType) throws IOException {

		File resultFile = new File(MODEL_PATH + NAME + featureType.toString() + ".args");
		PrintWriter resultWriter = new PrintWriter(resultFile);
		log.info("Printing same sentence arguments.");
		printSsArgs(corpus, resultWriter, featureType);

		log.info("Printing previous sentence arguments.");
		if (corpus.equals(Type.BIO_DRB)) {
			printBioPsArgs(resultWriter, featureType);
		} else {
			printPsArgs(resultWriter, featureType);
		}
		resultWriter.close();

		return resultFile;
	}

	private void makeBioPipeFile(String pipeDir, File outFile) throws IOException {
		log.info("Adding arguments to pipe files:");
		try (BufferedReader outReader = Util.reader(outFile)) {
			String out;
			Map<String, String> argResults = new HashMap<>();
			Set<String> articles = new HashSet<>();

			while ((out = outReader.readLine()) != null) {
				String[] outCols = out.split("\\|", -1);
				String article = outCols[outCols.length - 3] + ".pipe";
				String span = outCols[outCols.length - 2];
				String key = article + "_" + span;
				argResults.put(key, out);
				articles.add(article);
			}

			for (String article : articles) {
				log.trace("Article: " + article);
				File pipeFile = new File(pipeDir + "/" + article);
				String[] lines = Util.readFile(pipeFile).trim().split(Util.NEW_LINE);
				PrintWriter pipeWriter = new PrintWriter(pipeFile);

				for (String pipe : lines) {
					if (pipe.isEmpty()) {
						log.warn("Article:" + article + " has no pipes!");
						continue;
					}
					String[] cols = pipe.split("\\|", -1);
					if (cols.length != 27) {
						log.error("Invalid pipe file: " + article);
					}
					String argOut = argResults.get(article + "_" + cols[1]);
					if (argOut != null) {
						String[] arguments = argOut.split("\\|", -1);
						StringBuilder newPipe = new StringBuilder();

						for (int i = 0; i < cols.length; ++i) {
							if (i == 14) {
								newPipe.append(arguments[6]);
							} else if (i == 20) {
								newPipe.append(arguments[7]);
							} else {
								newPipe.append(cols[i]);
							}
							newPipe.append('|');
						}
						newPipe.deleteCharAt(newPipe.length() - 1);
						pipeWriter.println(newPipe);
					} else {
						log.warn("No argumnets for file: " + article);
						pipeWriter.println(pipe);
					}
				}
				pipeWriter.close();
			}
		}
	}

	private void makePipeFile(String pipeDir, File outFile) throws IOException {

		try (BufferedReader outReader = Util.reader(outFile)) {
			String out;
			Map<String, String> argResults = new HashMap<>();
			Set<String> articles = new HashSet<>();

			while ((out = outReader.readLine()) != null) {
				String[] outCols = out.split("\\|", -1);
				String article = outCols[outCols.length - 3];
				String span = outCols[outCols.length - 2];
				String key = article + "_" + span;
				argResults.put(key, out);
				articles.add(article);
			}

			for (String article : articles) {
				File pipeFile = new File(pipeDir + "/" + article);
				String[] lines = Util.readFile(pipeFile).split(Util.NEW_LINE);
				PrintWriter pipeWriter = new PrintWriter(pipeFile);

				for (String pipe : lines) {
					String[] cols = pipe.split("\\|", -1);
					String argOut = argResults.get(article + "_" + cols[3]);
					if (argOut != null) {
						String[] arguments = argOut.split("\\|", -1);
						boolean isSameSentence = "SS".equals(arguments[arguments.length - 1]);
						int sentenceNumber = Integer.parseInt(cols[7]);
						StringBuilder newPipe = new StringBuilder();

						for (int i = 0; i < cols.length; ++i) {
							if (i == 22) {
								newPipe.append(arguments[6]);
							} else if (i == 23) {
								newPipe.append(isSameSentence ? sentenceNumber : (sentenceNumber - 1));
							} else if (i == 24) {
								newPipe.append(arguments[2].replaceAll("\\|", "<PIPE>"));
							} else if (i == 32) {
								newPipe.append(arguments[7]);
							} else if (i == 33) {
								newPipe.append(sentenceNumber);
							} else if (i == 34) {
								newPipe.append(arguments[3].replaceAll("\\|", "<PIPE>"));
							} else {
								newPipe.append(cols[i]);
							}
							newPipe.append('|');
						}
						newPipe.deleteCharAt(newPipe.length() - 1);
						pipeWriter.println(newPipe);
					} else {
						pipeWriter.println(pipe);
					}
				}
				pipeWriter.close();
			}
		}
	}

	private void printBioPsArgs(PrintWriter resultWriter, FeatureType featureType) throws IOException {
		labels = getArgPosLabels(featureType);
		majorIndex = 0;

		File[] files = new File(Settings.BIO_DRB_ANN_PATH).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith(".txt");
			}
		});

		for (File article : files) {

			Map<String, String> spanHashMap = Corpus.getBioSpanMap(article, featureType);
			trees = Corpus.getBioTrees(article, featureType);
			orgText = Util.readFile(Settings.BIO_DRB_RAW_PATH + article.getName());
			orgText = orgText.replaceAll("`", "'");
			List<String> explicitSpans = Corpus.getBioExplicitSpans(article, featureType);
			ArrayList<String> spanArray = Corpus.getBioSpanMapAsList(article, featureType);

			if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
				explicitSpans = Corpus.filterBioErrorProp(explicitSpans, article, featureType);
			}
			for (String rel : explicitSpans) {
				String[] cols = rel.split("\\|", -1);

				String argPos = Corpus.getBioLabel(cols[14], cols[20], spanArray);
				if (argPos.equals("FS")) {
					continue;
				}

				String label = labels.get(majorIndex);
				majorIndex++;
				if (label.equals("PS")) {

					String[] args = getPSArgSpans(Type.BIO_DRB, rel, spanArray, spanHashMap, featureType);

					String arg1Exp = cols[14];
					String arg2Exp = cols[20];

					String resultLine = Corpus.spanToText(arg1Exp, orgText) + "|" + Corpus.spanToText(arg2Exp, orgText)
							+ "|" + Corpus.spanToText(args[0], orgText) + "|" + Corpus.spanToText(args[1], orgText)
							+ "|" + arg1Exp + "|" + arg2Exp + "|" + args[0] + "|" + args[1] + "|" + article.getName()
							+ "|" + cols[1] + "|PS";
					resultWriter.println(resultLine);
					resultWriter.flush();
				}
			}
		}
	}

	private void printPsArgs(PrintWriter resultWriter, FeatureType featureType) throws IOException {

		labels = getArgPosLabels(featureType);
		majorIndex = 0;

		for (int section : Settings.TEST_SECTIONS) {
			File[] files = Corpus.getSectionFiles(section);
			for (File article : files) {
				Map<String, String> spanHashMap = Corpus.getSpanMap(new File(article + ".pipe"), featureType);
				trees = Corpus.getTrees(new File(article + ".pipe"), featureType);
				if (featureType == FeatureType.Auto) {
					sentMap = Corpus.getSentMap(new File(article + ".pipe"));
				}
				orgText = Util.readFile(Corpus.genRawTextPath(article));
				orgText = orgText.replaceAll("`", "'");

				List<String> explicitSpans = Corpus.getExplicitSpans(article, featureType);

				if (featureType == FeatureType.ErrorPropagation || featureType == FeatureType.Auto) {
					explicitSpans = Corpus.filterErrorProp(explicitSpans, article, featureType);
				}
				for (String rel : explicitSpans) {
					String label = labels.get(majorIndex);
					majorIndex++;
					if (label.equals("PS")) {
						String[] cols = rel.split("\\|", -1);
						String[] args = getPSArgSpans(Type.PDTB, rel, null, spanHashMap, featureType);

						String arg1Exp = cols[22];
						String arg2Exp = cols[32];

						String resultLine = Corpus.spanToText(arg1Exp, orgText) + "|"
								+ Corpus.spanToText(arg2Exp, orgText) + "|" + Corpus.spanToText(args[0], orgText) + "|"
								+ Corpus.spanToText(args[1], orgText) + "|" + arg1Exp + "|" + arg2Exp + "|" + args[0]
								+ "|" + args[1] + "|" + article.getName() + "|" + cols[3] + "|PS";
						resultWriter.println(resultLine);
						resultWriter.flush();
					}
				}
			}
		}

	}

	private String[] getPSArgSpans(Type corpus, String pipe, ArrayList<String> spanArray,
			Map<String, String> spanHashMap, FeatureType featureType) throws IOException {

		String[] cols = pipe.split("\\|", -1);

		String connSpan = cols[corpus.equals(Type.PDTB) ? 3 : 1];
		String[] connGorn = null;
		if (corpus.equals(Type.PDTB)) {
			connGorn = cols[4].split(";");
		} else {
			LinkedList<Integer> temp = Corpus.spanToSenIds(cols[1], spanArray);
			Set<Integer> set = new HashSet<>(temp);
			connGorn = new String[set.size()];
			int i = 0;
			for (Integer t : set) {
				connGorn[i] = t.toString();
				++i;
			}
		}
		int connTree = -1;

		for (String conn : connGorn) {
			String[] par = conn.split(",");
			int tmp = Integer.parseInt(par[0]);
			if (!(connTree != -1 && connTree == tmp)) {
				connTree = tmp;
			}
		}

		int autoConnTree = getNodeNum(connTree, featureType);

		Tree arg2Root = trees.get(autoConnTree);
		String arg2 = (autoConnTree) + ":" + arg2Root.firstChild().nodeNumber(arg2Root);
		ArrayList<String> arg2Nodes = new ArrayList<String>();
		arg2Nodes.add(arg2);

		String arg2Span = calcNodesSpan(arg2Nodes, spanHashMap, connSpan, null);

		String arg1Span = "1..2";

		if (autoConnTree > 0) {
			int autoConnTree1 = getNodeNum(connTree - 1, featureType);
			Tree arg1Root = trees.get(autoConnTree1);
			String arg1 = (autoConnTree1) + ":" + arg1Root.firstChild().nodeNumber(arg1Root);
			ArrayList<String> arg1Nodes = new ArrayList<String>();
			arg1Nodes.add(arg1);
			arg1Span = calcNodesSpan(arg1Nodes, spanHashMap, connSpan, arg2Nodes);
		}

		return new String[] { arg1Span, arg2Span };
	}

	private void printSsArgs(Type corpus, PrintWriter resultWriter, FeatureType featureType) throws IOException {

		String prefix = MODEL_PATH + NAME + featureType.toString();
		try (BufferedReader er = Util.reader(prefix + ".aux");
				BufferedReader prd = Util.reader(prefix + ".out");
				BufferedReader pp = Util.reader(prefix + ".pipe");
				BufferedReader tst = Util.reader(prefix)) {
			String tmp;
			while ((tmp = er.readLine()) != null) {
				String[] line = tmp.split(":");
				String article = line[0];
				String path = null;
				Map<String, String> spanHashMap = null;

				if (corpus.equals(Type.BIO_DRB)) {
					path = Settings.BIO_DRB_RAW_PATH + article;
					spanHashMap = Corpus.getBioSpanMap(new File(article), featureType);
					trees = Corpus.getBioTrees(new File(article), featureType);

				} else {
					path = Corpus.genRawTextPath(new File(article));
					spanHashMap = Corpus.getSpanMap(new File(article), featureType);
					trees = Corpus.getTrees(new File(article), featureType);
					if (featureType == FeatureType.Auto) {
						sentMap = Corpus.getSentMap(new File(article));
					}
				}
				orgText = Util.readFile(path);
				orgText = orgText.replaceAll("`", "'");

				String[] index = line[1].split("\\-");
				int stIndex = Integer.parseInt(index[0]);
				int endIndex = Integer.parseInt(index[1]);
				List<String> arg1Nodes = new ArrayList<>();
				List<String> arg2Nodes = new ArrayList<>();
				double arg1Max = 0, arg2Max = 0;
				int arg1Ind = 0;

				String[] nodes = new String[endIndex - stIndex];
				String[][] vals = new String[endIndex - stIndex][];
				for (int i = stIndex; i < endIndex; ++i) {
					tmp = prd.readLine();

					vals[i - stIndex] = tmp.split("\\s+");
					tmp = tst.readLine();
					nodes[i - stIndex] = tmp.substring(tmp.lastIndexOf(' ')).trim();

					if (i + 1 < endIndex) {
						tmp = er.readLine();
						if (tmp == null) {
							log.error("out");
							break;
						}
					}
				}

				for (int i = 0; i < nodes.length; ++i) {
					double val = Double
							.parseDouble(vals[i][1].substring(vals[i][1].indexOf('[') + 1, vals[i][1].indexOf(']')));
					if (val > arg1Max) {
						arg1Ind = i;
						arg1Nodes.clear();
						arg1Nodes.add(nodes[i]);
						arg1Max = val;
					}
				}

				for (int i = 0; i < nodes.length; ++i) {
					double val = Double
							.parseDouble(vals[i][2].substring(vals[i][2].indexOf('[') + 1, vals[i][2].indexOf(']')));
					if (val > arg2Max && arg1Ind != i) {
						arg2Nodes.clear();
						arg2Nodes.add(nodes[i]);
						arg2Max = val;
					}
				}
				String arg1Exp = line[2].substring(line[2].indexOf('(') + 1, line[2].lastIndexOf(')'));
				String arg2Exp = line[3].substring(line[3].indexOf('(') + 1, line[3].lastIndexOf(')'));

				String arg2Prd = calcNodesSpan(arg2Nodes, spanHashMap, line[4], null);
				String arg1Prd = calcNodesSpan(arg1Nodes, spanHashMap, line[4], arg2Nodes);

				String resultLine = Corpus.spanToText(arg1Exp, orgText) + "|" + Corpus.spanToText(arg2Exp, orgText)
						+ "|" + Corpus.spanToText(arg1Prd, orgText) + "|" + Corpus.spanToText(arg2Prd, orgText) + "|"
						+ arg1Exp + "|" + arg2Exp + "|" + arg1Prd + "|" + arg2Prd + "|" + article + "|" + line[4]
						+ "|SS";
				resultWriter.println(resultLine);
				resultWriter.flush();
			}
		}
	}

	private String calcNodesSpan(List<String> nodes, Map<String, String> spanHashMap, String connSpan,
			List<String> otherArg) {
		Set<String> conn = new HashSet<>();
		String[] c = connSpan.split(";");
		for (String e : c) {
			conn.add(e);
		}
		List<Span> spans = new ArrayList<>();
		String[] d = otherArg != null ? otherArg.get(0).split(":") : null;
		int skipTreeNum = -1;
		int skipNodeNumber = -1;
		if (d != null) {
			skipTreeNum = Integer.parseInt(d[0]);
			skipNodeNumber = Integer.parseInt(d[1]);
		}
		// for debugging purposes
		@SuppressWarnings("unused")
		Tree skipNode = d != null ? trees.get(skipTreeNum).getNodeNumber(skipNodeNumber) : null;
		for (String txt : nodes) {
			String[] tmp = txt.split(":");
			int treeNum = Integer.parseInt(tmp[0]);
			Tree root = trees.get(treeNum);
			Tree node = root.getNodeNumber(Integer.parseInt(tmp[1]));
			if (node == null) {
				continue;
			}
			Queue<Tree> children = new LinkedList<>();
			children.add(node);
			while (children.size() > 0) {
				Tree child = children.poll();
				// the same tree and the same node number as the other argument
				if (skipTreeNum == treeNum && child.nodeNumber(root) == skipNodeNumber) {
					continue;
				} else if (!child.isLeaf()) {
					children.addAll(child.getChildrenAsList());
				} else {
					int nodeNum = child.nodeNumber(root);
					String span = spanHashMap.get(treeNum + ":" + nodeNum);
					if (span != null && !hasIntersection(span, conn)) {
						spans.add(new Span(span));
					}
				}
			}
		}

		Collections.sort(spans);
		StringBuilder sb = new StringBuilder();
		for (Span span : spans) {
			if (sb.length() > 0) {
				String end = sb.substring(sb.lastIndexOf(".") + 1);
				String start = Integer.toString(span.start);
				if (Integer.parseInt(start) - Integer.parseInt(end) > 2) {
					sb.append(";");
					sb.append(span);
				} else {
					sb.delete(sb.lastIndexOf(".") + 1, sb.length());
					try {
						end = Integer.toString(span.end);
					} catch (StringIndexOutOfBoundsException e) {
						log.error("Error: " + e.getMessage());
						e.printStackTrace();
					}
					sb.append(end);
				}
			} else {
				sb.append(span);
			}
		}

		String result = sb.toString();
		String out = removePunctuation(result);
		return out;
	}

	private String removePunctuation(String sb) {
		String[] result = sb.split(";");
		String out = "";
		if (sb.length() > 0) {
			for (String span : result) {
				if (out.length() > 0 && out.charAt(out.length() - 1) != ';') {
					out += ";";
				}
				int[] tmp = Corpus.spanToInt(span);
				char[] text = orgText.substring(tmp[0], tmp[1]).toCharArray();
				int i = 0;
				for (; i < text.length; ++i) {
					if (Character.isAlphabetic(text[i]) || Character.isDigit(text[i]) || text[i] == '%'
							|| text[i] == '(') {
						break;
					}
				}
				tmp[0] += i;
				for (i = text.length - 1; i > 0; --i) {
					if (Character.isAlphabetic(text[i]) || Character.isDigit(text[i]) || text[i] == '%'
							|| text[i] == ')') {
						break;
					}
				}
				tmp[1] -= text.length - 1 - i;
				if (tmp[1] - tmp[0] > 0) {
					out += tmp[0] + ".." + tmp[1];
				}
			}
		}
		if (out.endsWith(";")) {
			out = out.substring(0, out.length() - 1);
		}

		return out;
	}

	static class Span implements Comparable<Span> {
		int start;
		int end;

		@Override
		public int compareTo(Span o) {
			return start - o.start;
		}

		Span(String span) {
			String[] tmp = span.split("\\.\\.");
			start = Integer.parseInt(tmp[0]);
			end = Integer.parseInt(tmp[1]);
		}

		@Override
		public String toString() {
			return start + ".." + end;
		}
	}

	private static boolean hasIntersection(String span, Set<String> conn) {
		for (String c : conn) {
			if (span.equals(c)) {
				return true;
			}
			if (spansIntersect(span, c)) {
				return true;
			}
		}

		return false;
	}

	private static boolean spansIntersect(String span, String c) {

		if (span == null || c == null) {
			return false;
		}

		String[] sp = span.split("\\.\\.");
		String[] cc = c.split("\\.\\.");

		int[] spInt = { Integer.parseInt(sp[0]), Integer.parseInt(sp[1]) };
		int[] ccInt = { Integer.parseInt(cc[0]), Integer.parseInt(cc[1]) };
		if (spInt[0] <= ccInt[0] && ccInt[1] <= spInt[1]) {
			return true;
		}
		if (spInt[0] <= ccInt[0] && ccInt[0] <= spInt[1]) {
			return true;
		}
		if (spInt[0] <= ccInt[1] && ccInt[1] <= spInt[1]) {
			return true;
		}
		if (ccInt[0] <= spInt[0] && spInt[1] <= ccInt[1]) {
			return true;
		}
		return false;
	}

}
