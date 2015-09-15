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
import static sg.edu.nus.comp.pdtb.util.Settings.TMP_PATH;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import edu.stanford.nlp.trees.Tree;
import sg.edu.nus.comp.pdtb.model.Dependency;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.model.Stemmer;
import sg.edu.nus.comp.pdtb.model.TreeNode;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class NonExplicitComp extends Component {

	public static final String NAME = "nonexp";

	private static final String[] LEVEL_1_TYPES = { "Expansion", "Contingency", "Comparison", "Temporal" };

	private static final String[] LEVEL_2_TYPES = { "Alternative", "Asynchronous", "Cause", "Concession", "Conjunction",
			"Contrast", "Instantiation", "List", "Pragmatic cause", "Restatement", "Synchrony" };

	private List<Tree> trees;

	private HashMap<String, Dependency> dtreeMap;

	private Map<String, Double> featureProdRules;
	private Map<String, Double> featureDepRules;
	private Map<String, Double> featureWordPairs;

	private static final int NUM_PROD_RULES = 100;
	private static final int NUM_DEP_RULES = 100;
	private static final int NUM_WORD_PAIRS = 500;

	private static final int PHRASE_LENGTH = 3;

	public NonExplicitComp() throws IOException {
		super(NAME, NonExplicitComp.class.getName());

		featureProdRules = initRules(Settings.PROD_RULES_FILE, NUM_PROD_RULES);
		featureDepRules = initRules(Settings.DEP_RULES_FILE, NUM_DEP_RULES);
		featureWordPairs = initRules(Settings.WORD_PAIRS_FILE, NUM_WORD_PAIRS);
	}

	private Map<String, Double> initRules(String fileName, int maxSize) throws IOException {
		Map<String, Double> result = new HashMap<String, Double>();
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(fileName), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null && result.size() < maxSize) {
				String[] tokens = line.split("\\s+");
				int n = tokens.length;

				String rule = tokens[0];
				if (tokens[n - 1] != null) {
					Double value = Double.parseDouble(tokens[n - 1]);
					if (!result.containsKey(rule)) {
						result.put(rule, value);
					}
				}
			}

		}

		return result;
	}

	protected void initTrees(File article, FeatureType featureType) throws IOException {
		trees = Corpus.getTrees(article, featureType);
	}

	@Override
	public File test(File model, FeatureType featureType) throws IOException {
		String name = this.name + featureType.toString();
		File testFile = new File(OUT_PATH + name);
		PrintWriter featureFile = new PrintWriter(testFile);

		String dir = OUT_PATH + name.replace('.', '_') + "/";
		new File(dir).mkdirs();

		log.info("Testing (" + featureType + "):");
		for (int section : Settings.TEST_SECTIONS) {
			log.info("Section: " + section);
			File[] files = Corpus.getSectionFiles(section);

			for (File file : files) {
				log.trace("Article: " + file.getName());

				String articleId = file.getName().substring(0, 8);

				String articleName = dir + articleId;

				File articleTest = new File(articleName + ".features");
				PrintWriter articleFeatures = new PrintWriter(articleTest);
				File articleAux = new File(articleName + ".aux");
				PrintWriter articleAuxWriter = new PrintWriter(articleAux);

				List<String[]> features = null;
				if (featureType == FeatureType.GoldStandard) {
					features = generateFeatures(file, featureType);
				} else {
					features = generateEpFeatures(file, featureType);
				}
				for (String[] feature : features) {
					featureFile.println(feature[0]);
					articleFeatures.println(feature[0]);
					articleAuxWriter.println(feature[1]);
				}

				featureFile.flush();
				articleFeatures.close();
				articleAuxWriter.close();

				File articleOut = MaxEntClassifier.predict(testFile, modelFile,
						new File(Settings.OUT_PATH + name + ".out"));
				String pipeDir = OUT_PATH + "pipes" + featureType.toString().replace('.', '_');
				new File(pipeDir).mkdirs();
				makePipeFile(pipeDir, articleOut, articleAux, file.getName());
			}
		}
		featureFile.close();

		File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(Settings.OUT_PATH + name + ".out"));

		return outFile;
	}

	private File makePipeFile(String pipeDir, File articleOut, File articleAux, String article) throws IOException {
		File pipeFile = new File(pipeDir + "/" + article);

		try (FileWriter writer = new FileWriter(pipeFile, true);
				BufferedReader read = Util.reader(articleOut);
				BufferedReader auxRead = Util.reader(articleAux);) {
			String aux;
			while ((aux = auxRead.readLine()) != null) {
				String[] tmp = read.readLine().split("\\s+");
				String[] cols = aux.split("\\|", -1);
				String fullSense = Corpus.getFullSense(tmp[tmp.length - 1]);
				if (fullSense.equals("EntRel") || fullSense.equals("AltLex")) {
					aux = aux.replaceAll("Implicit\\|", fullSense + "|");
					writer.write(aux + Util.NEW_LINE);
				} else {
					StringBuilder sb = new StringBuilder();
					for (int i = 0; i < 48; ++i) {
						sb.append((i == 11) ? fullSense : cols[i]);
						sb.append("|");
					}
					sb.deleteCharAt(sb.length() - 1);
					writer.write(sb.toString() + Util.NEW_LINE);
				}
			}
		}
		return pipeFile;
	}

	private List<String[]> generateEpFeatures(File article, FeatureType featureType) throws IOException {

		trees = Corpus.getNonExpTrees(article, featureType);
		if (featureType == FeatureType.Auto || dtreeMap == null) {
			buildDependencyTrees(article, featureType);
		}

		List<String[]> features = new ArrayList<>();
		int[] paragraphs = Corpus.getParagraphs(article, featureType);

		List<String> relations = getEpRelations(article, featureType);

		List<String> impRel = null;
		if (featureType != FeatureType.AnyText) {
			impRel = Corpus.getNonExplicitSpans(article);
		}

		for (int i = 0; i < paragraphs.length; ++i) {
			int index = paragraphs[i];
			int limit = ((i + 1) < paragraphs.length ? paragraphs[i + 1] : trees.size()) - 1;
			for (; index < limit; ++index) {
				int senIdx1 = index;
				int senIdx2 = index + 1;
				String expRel = findRelation(relations, "Exp", senIdx1, senIdx2);

				if (expRel == null) {
					String nonExpRel = featureType == FeatureType.AnyText ? null
							: findRelation(impRel, "NonExp", senIdx1, senIdx2);
					String[] types = null;

					if (nonExpRel != null) {
						types = getTypes(nonExpRel);
					}

					if (types != null && types[0].isEmpty()) {// no level 2 type
						continue;
					}

					if (featureType == FeatureType.AnyText || types != null) { // else
																				// just
																				// +1
																				// for
																				// total
						// print to feature file
						StringBuilder feature = new StringBuilder();
						Tree arg1Tree = trees.get(senIdx1);
						Tree arg2Tree = trees.get(senIdx2);

						List<TreeNode> arg1 = new ArrayList<>();
						arg1.add(new TreeNode(arg1Tree.firstChild(), arg1Tree.firstChild(), senIdx1));

						List<TreeNode> arg2 = new ArrayList<>();
						arg2.add(new TreeNode(arg2Tree.firstChild(), arg2Tree.firstChild(), senIdx2));

						String productionRules = printProductionRules(arg1, arg2);
						feature.append(productionRules);

						String dependencyRules = printDependencyRules(arg1, arg2);
						feature.append(dependencyRules);

						String wordPairs = printWordPairs(arg1, arg2);
						feature.append(wordPairs);
						String arg2Word = printArg2Word(arg1, arg2);
						feature.append(arg2Word);

						if (featureType != FeatureType.AnyText) {
							for (String type : types) {
								feature.append(type.replace(' ', '_'));
								feature.append('£');
							}
						} else {
							feature.append("xxx");
						}
						if (featureType != FeatureType.Training && featureType != FeatureType.GoldStandard) {
							nonExpRel = genNonExpRel(arg1Tree, arg2Tree, senIdx1, senIdx2);
						}
						features.add(new String[] { feature.toString(), nonExpRel });
					}
				}
			}
		}

		return features;
	}

	private String genNonExpRel(Tree arg1Tree, Tree arg2Tree, int senIdx1, int senIdx2) {
		List<Tree> arg1Pos = new ArrayList<>();
		getAllPosNodes(arg1Tree, arg1Pos);
		List<Tree> arg2Pos = new ArrayList<>();
		getAllPosNodes(arg2Tree, arg2Pos);

		String arg1Text = Corpus.nodesToString(arg1Pos);
		String arg2Text = Corpus.nodesToString(arg2Pos);

		StringBuilder sb = new StringBuilder();

		for (int i = 0; i < 48; ++i) {
			if (i == 0) {
				sb.append("Implicit");
			}
			if (i == 23) {
				sb.append(senIdx1);
			}
			if (i == 24) {
				sb.append(arg1Text);
			}
			if (i == 33) {
				sb.append(senIdx2);
			}
			if (i == 34) {
				sb.append(arg2Text);
			}
			sb.append("|");
		}
		sb.deleteCharAt(sb.length() - 1);

		return sb.toString();
	}

	private List<String> getEpRelations(File article, FeatureType featureType) throws IOException {
		StringBuilder path = new StringBuilder();
		if (featureType == FeatureType.AnyText) {
			path.append(Settings.TMP_PATH);
			path.append(article.getName());
			path.append(".pipe");
		} else {
			path.append(OUT_PATH);
			path.append("pipes");
			path.append(featureType.toString().replace('.', '_'));
			path.append('/');
			path.append(article.getName());
		}
		List<String> result = new ArrayList<>();
		try {
			String[] pipes = Util.readFile(path.toString()).split(Util.NEW_LINE);
			for (String pipe : pipes) {
				if (pipe.length() > 0) {
					String[] rel = pipe.split("\\|", -1);
					if (rel.length != 48) {
						log.error("Invalid EP arg_ext relations. Column size should be 48 but it was " + rel.length
								+ " in article " + article + " pipe " + pipe);
					}

					result.add(pipe);
				}
			}
		} catch (FileNotFoundException e) {
			log.info("No EP arguments for article: " + article.getName() + " : " + e.getMessage());
		}

		return result;
	}

	private String printWordPairs(List<TreeNode> arg1TreeNodes, List<TreeNode> arg2TreeNodes) {
		String arg1 = treeNodeToText(arg1TreeNodes);
		String arg2 = treeNodeToText(arg2TreeNodes);

		return printWordPairs(arg1, arg2);
	}

	private static String[] getTypes(String rel) {

		if (rel.startsWith("EntRel")) {
			return new String[] { "EntRel" };
		} else if (rel.startsWith("NoRel")) {
			return new String[] { "NoRel" };
		} else {
			String[] cols = rel.split("\\|", -1);
			String[] senses = new String[] { cols[11], cols[12], cols[13], cols[14] };
			Set<String> types = Util.getUniqueSense(senses);
			if (types.isEmpty()) {
				return new String[] { "" };
			} else {
				return types.toArray(new String[types.size()]);
			}
		}
	}

	private String findRelation(List<String> relations, String type, int senId1, int senId2) {

		for (String rel : relations) {
			if ((type.equals("Exp") && rel.startsWith("Explicit"))
					|| (type.equals("NonExp") && !rel.startsWith("Explicit"))) {
				String[] cols = rel.split("\\|", -1);
				String[] tmp = cols[23].split(";");
				String arg1Gorn = tmp[tmp.length - 1].split(",")[0].trim();
				String arg2Gorn = cols[33].split(";")[0].split(",")[0].trim();

				if (arg1Gorn.length() > 0 && arg2Gorn.length() > 0) {
					int sen1 = Integer.parseInt(arg1Gorn);
					int sen2 = Integer.parseInt(arg2Gorn);
					if (sen1 == senId1 && sen2 == senId2) {
						return rel;
					}
				}
			}
		}
		return null;
	}

	@Override
	public List<String[]> generateFeatures(File article, FeatureType featureType) throws IOException {

		trees = Corpus.getTrees(article, featureType);

		buildDependencyTrees(article, featureType);

		List<String[]> features = new ArrayList<>();

		List<String> relations = Corpus.getNonExplicitSpans(article);
		for (String rel : relations) {
			StringBuilder feature = new StringBuilder();

			String out = printProductionRules(rel);
			feature.append(out);

			out = printDependencyRules(rel);
			feature.append(out);

			out = printWordPairs(rel);
			feature.append(out);

			out = printArg2WordFromPipeline(rel);
			feature.append(out);

			String[] cols = rel.split("\\|", -1);
			String[] senses = new String[] { cols[11], cols[12], cols[13], cols[14] };

			Set<String> types = new HashSet<>();
			if (cols[0].matches("Implicit|AltLex")) {
				types = Util.getUniqueSense(senses);
			} else {
				types.add(cols[0]);
			}

			if (featureType == FeatureType.Training) {
				for (String type : types) {
					// Check if valid type, since we may only use subset of all
					// possible types.
					if (type.matches("EntRel|NoRel") || isLegalType(type)) {
						StringBuilder sb = new StringBuilder(feature);
						sb.append(type.replace(' ', '_'));
						features.add(new String[] { sb.toString(), rel });
					}
				}
			} else {
				if (types.size() > 0) {
					for (String type : types) {
						feature.append(type.replace(' ', '_'));
						feature.append('£');
					}
					features.add(new String[] { feature.toString(), rel });
				}
			}
		}

		return features;
	}

	private boolean isLegalType(String type) {
		String[] legalTypes = (Settings.SEMANTIC_LEVEL == 1) ? LEVEL_1_TYPES : LEVEL_2_TYPES;
		return Util.arrayContains(legalTypes, type);
	}

	private String printProductionRules(String relation) {
		List<TreeNode> arg1 = getTreeNodes(relation, "arg1");
		List<TreeNode> arg2 = getTreeNodes(relation, "arg2");
		return printProductionRules(arg1, arg2);
	}

	private String printProductionRules(List<TreeNode> arg1, List<TreeNode> arg2) {
		StringBuilder line = new StringBuilder();
		HashMap<String, Integer> pRules1 = new HashMap<String, Integer>();
		for (TreeNode tree : arg1) {
			getProductionRules(tree.getNode(), pRules1);
		}

		HashMap<String, Integer> pRules2 = new HashMap<String, Integer>();
		for (TreeNode tree : arg2) {
			getProductionRules(tree.getNode(), pRules2);
		}

		HashSet<String> pRules = new HashSet<String>();
		pRules.addAll(pRules1.keySet());
		pRules.addAll(pRules2.keySet());

		LinkedList<Entry<String, Double>> list = new LinkedList<Entry<String, Double>>(featureProdRules.entrySet());

		Collections.sort(list, new Comparator<Entry<String, Double>>() {
			@Override
			public int compare(Entry<String, Double> o1, Entry<String, Double> o2) {
				return Double.compare(o2.getValue(), o1.getValue());
			}
		});

		for (Entry<String, Double> item : list) {
			String key = item.getKey();

			if (pRules.contains(key)) {
				boolean a1 = pRules1.containsKey(key);
				boolean a2 = pRules2.containsKey(key);

				if (a1) {
					line.append(key + ":1 ");
				}

				if (a2) {
					line.append(key + ":2 ");
				}

				if (a1 && a2) {
					line.append(key + ":12 ");
				}
			}
		}

		return line.toString();
	}

	public static void getProductionRules(Tree tree, HashMap<String, Integer> prodRules) {
		String[] tr = tree.value().replaceAll("=[0-9]+", "").split("-");
		String value = tr.length > 0 ? tr[0] : tree.value();
		if (tree.isLeaf() || tree.value().startsWith("-")) {
			value = tree.value();
		}
		StringBuilder rule = new StringBuilder(value);
		rule.append(" ->");
		for (Tree child : tree.children()) {
			if (!child.value().equalsIgnoreCase("-NONE-")) {
				String[] tmp = child.value().replaceAll("=[0-9]+", "").split("-");
				String cVal = tmp.length > 0 ? tmp[0] : child.value();
				if (child.isLeaf() || child.value().startsWith("-")) {
					cVal = child.value();
				}
				rule.append(" ");
				rule.append(cVal);
			}
		}
		String key = rule.toString().replaceAll("\\s+", "_");

		// has some child values
		if (!key.endsWith("->")) {
			Integer count = prodRules.get(key);
			if (count == null) {
				count = 0;
			}
			++count;
			prodRules.put(key, count);
		}

		for (Tree child : tree.children()) {
			if (!child.value().equalsIgnoreCase("-NONE-")) {
				getProductionRules(child, prodRules);
			}
		}

	}

	private List<TreeNode> getTreeNodes(String relation, String arg) {

		String[] cols = relation.split("\\|", -1);
		String gornAddress = cols[arg.equals("arg1") ? 23 : 33];
		String[] treeAddress = gornAddress.split(";");
		List<TreeNode> result = new ArrayList<TreeNode>();
		for (String address : treeAddress) {
			String[] tmp = address.split(",");
			int senIdx = Integer.parseInt(tmp[0]);
			Tree tree = trees.get(senIdx).getChild(0);
			Tree node = tree;
			for (int i = 1; i < tmp.length; ++i) {
				int childId = Integer.parseInt(tmp[i]);
				node = node.getChild(childId);
			}

			result.add(new TreeNode(tree, node, senIdx));
		}
		return result;
	}

	private String printWordPairs(String rel) {
		String[] cols = rel.split("\\|", -1);
		String arg1 = cols[24];
		String arg2 = cols[34];

		return printWordPairs(arg1, arg2);
	}

	private String printWordPairs(String arg1, String arg2) {
		StringBuilder line = new StringBuilder();
		arg1 = arg1.toLowerCase();
		arg2 = arg2.toLowerCase();

		arg1 = tokenize(arg1);
		arg2 = tokenize(arg2);

		String[] text1 = arg1.split("\\s+");
		String[] text2 = arg2.split("\\s+");

		for (int i = 0; i < text1.length; ++i) {
			text1[i] = stem(text1[i]);
		}

		for (int i = 0; i < text2.length; ++i) {
			text2[i] = stem(text2[i]);
		}
		Set<String> pairs = new HashSet<String>();
		for (String w1 : text1) {
			for (String w2 : text2) {
				String pair = w1 + "_" + w2;
				pairs.add(pair);
			}
		}

		List<String> list = new LinkedList<String>(pairs);
		Collections.sort(list);

		for (String pair : list) {
			if (featureWordPairs.containsKey(pair)) {
				line.append(pair + " ");
			}
		}
		return line.toString();
	}

	private String printDependencyRules(String rel) {
		List<TreeNode> arg1 = getTreeNodes(rel, "arg1");
		List<TreeNode> arg2 = getTreeNodes(rel, "arg2");
		return printDependencyRules(arg1, arg2);
	}

	private String printDependencyRules(List<TreeNode> arg1, List<TreeNode> arg2) {
		StringBuilder line = new StringBuilder();

		HashMap<String, Integer> depRules1 = new HashMap<String, Integer>();
		for (TreeNode pair : arg1) {
			getDependencyRules(pair, dtreeMap, depRules1);
		}

		HashMap<String, Integer> depRules2 = new HashMap<String, Integer>();
		for (TreeNode pair : arg2) {
			getDependencyRules(pair, dtreeMap, depRules2);
		}

		HashSet<String> depRules = new HashSet<String>();
		depRules.addAll(depRules1.keySet());
		depRules.addAll(depRules2.keySet());

		LinkedList<Entry<String, Double>> list = new LinkedList<Entry<String, Double>>(featureDepRules.entrySet());

		Collections.sort(list, new Comparator<Entry<String, Double>>() {
			@Override
			public int compare(Entry<String, Double> o1, Entry<String, Double> o2) {
				int r = Double.compare(o2.getValue(), o1.getValue());
				if (r == 0) {
					r = o1.getKey().compareTo(o2.getKey());
				}
				return r;
			}
		});

		for (Entry<String, Double> item : list) {
			String key = item.getKey();

			if (depRules.contains(key)) {
				boolean a1 = depRules1.containsKey(key);
				boolean a2 = depRules2.containsKey(key);

				if (a1) {
					line.append(key + ":1 ");
				}

				if (a2) {
					line.append(key + ":2 ");
				}

				if (a1 && a2) {
					line.append(key + ":12 ");
				}
			}
		}
		return line.toString();
	}

	public static void getDependencyRules(TreeNode treeNode, HashMap<String, Dependency> dtreeMap,
			HashMap<String, Integer> depRules) {

		Tree root = treeNode.getRoot();
		Tree node = treeNode.getNode();
		int treeNumber = treeNode.getTreeNumber();

		List<Tree> allPosNodes = new ArrayList<Tree>();
		getAllPosNodes(node, allPosNodes);

		List<Integer> leafNodes = new ArrayList<Integer>();
		for (Tree pn : allPosNodes) {
			leafNodes.add(pn.firstChild().nodeNumber(root));
		}

		for (int i = 0; i < leafNodes.size(); ++i) {
			Tree n = root.getNodeNumber(leafNodes.get(i));
			int nInd = n.nodeNumber(root);
			Dependency nDepRel = dtreeMap.get(treeNumber + " : " + nInd);
			if (nDepRel != null) {
				List<Tree> nDependents = new ArrayList<Tree>();
				for (Integer ind : nDepRel.getDependents()) {
					if (leafNodes.contains(ind)) {
						Tree d = root.getNodeNumber(ind);
						nDependents.add(d);
					}
				}

				if (nDependents.size() > 0) { // has nDependents

					String rule = n.value() + " <- ";

					for (Tree n1 : nDependents) {
						int n1Ind = n1.nodeNumber(root);
						Dependency n1DepRel = dtreeMap.get(treeNumber + " : " + n1Ind);
						String dependency = n1DepRel.getLabel();
						rule += "<" + dependency + "> ";
					}
					rule = rule.trim();

					if (!rule.endsWith("<-")) { // rule has some child values
						rule = rule.replace(' ', '_');
						Integer value = depRules.containsKey(rule) ? depRules.get(rule) : 0;
						value += 1;
						depRules.put(rule, value);
					}
				}
			}
		}
	}

	private String printArg2Word(List<TreeNode> arg1, List<TreeNode> arg2TreeNodes) {
		String arg2 = treeNodeToText(arg2TreeNodes);
		return printArg2Word(arg2);
	}

	private String printArg2Word(String arg2) {
		StringBuilder line = new StringBuilder();
		String[] ary = arg2.toLowerCase().split("\\s+");
		for (int i = 0; i < PHRASE_LENGTH && i < ary.length; ++i) {
			line.append("arg2_start_uni_" + ary[i] + " ");
		}

		return line.toString();
	}

	private String printArg2WordFromPipeline(String relation) {
		String[] tmp = relation.split("\\|", -1);
		return printArg2Word(tmp[34]);
	}

	protected void buildDependencyTrees(File article, FeatureType featureType) throws IOException {
		dtreeMap = new HashMap<String, Dependency>();
		String[] dtreeTexts = Corpus.getDependTrees(article, featureType);

		if (dtreeTexts.length != trees.size()) {
			logDiffTreeCountErr(dtreeTexts.length, article, featureType);
		}

		for (int i = 0; i < dtreeTexts.length; i++) {
			String dtreeText = dtreeTexts[i];

			if (dtreeText.isEmpty() || trees.get(i).children().length == 0) {
				continue;
			}

			Tree tree = trees.get(i).getChild(0);
			List<Tree> allPosNodes = new ArrayList<Tree>();
			getAllPosNodes(tree, allPosNodes);
			String[] rels = dtreeText.split("\n");

			// if there is no dependency tree for the parse tree
			if (rels.length == 0 || (rels.length == 1 && rels[0].isEmpty())) {
				continue;
			}

			for (String tmp : rels) {
				if (tmp.equals("_nil_") || tmp.startsWith("root") || tmp.isEmpty()) {
					continue;
				}
				int ind1 = tmp.indexOf('(');
				int ind2 = tmp.lastIndexOf(')');
				int split = tmp.indexOf(", ");

				String label = tmp.substring(0, ind1);

				String tmp1 = tmp.substring(ind1 + 1, split);
				String w1 = tmp1.substring(tmp1.lastIndexOf('-') + 1);

				String tmp2 = tmp.substring(split + 2, ind2);
				String w2 = tmp2.substring(tmp2.lastIndexOf('-') + 1);

				w1 = w1.replaceAll("[^\\d]", "");
				w2 = w2.replaceAll("[^\\d]", "");

				int pInd = Integer.parseInt(w1) - 1;
				int cInd = Integer.parseInt(w2) - 1;

				Tree p = allPosNodes.get(pInd).firstChild();
				Tree c = allPosNodes.get(cInd).firstChild();

				pInd = p.nodeNumber(tree);
				cInd = c.nodeNumber(tree);

				Dependency pDep = dtreeMap.get(i + " : " + pInd);
				if (pDep == null) {
					pDep = new Dependency(p);
				}

				Dependency cDep = dtreeMap.get(i + " : " + cInd);
				if (cDep == null) {
					cDep = new Dependency(c);
				}

				pDep.addDependents(cInd);
				cDep.setDependsOn(p);
				cDep.setLabel(label);

				dtreeMap.put(i + " : " + cInd, cDep);
				dtreeMap.put(i + " : " + pInd, pDep);
			}
		}
	}

	private void logDiffTreeCountErr(int dtreeLength, File article, FeatureType featureType) {
		StringBuilder msg = new StringBuilder();
		msg.append("The number of dependency trees (");
		msg.append(dtreeLength);
		msg.append(") and parse trees (");
		msg.append(trees.size());
		msg.append(") differ in article ");
		msg.append(article.getName());
		msg.append(" with feature type \"");
		msg.append(featureType);
		msg.append("\".");
		log.error(msg.toString());
	}

	public static void getAllPosNodes(Tree node, List<Tree> allPosNodes) {
		boolean isPos = node.numChildren() == 1 && node.firstChild().isLeaf();
		if (!isPos) {
			for (Tree child : node.children()) {
				getAllPosNodes(child, allPosNodes);
			}
		} else {
			if (!node.value().equalsIgnoreCase("-NONE-")) {
				allPosNodes.add(node);
			}
		}
	}

	/**
	 * Prepare text to be split into tokens according the Penn Treebank
	 * tokenization rules. After calling this method call
	 * {@code text.split("\\s+")} to get the actual tokens.
	 * 
	 * <p>
	 * Based upon the sed script written by Robert MacIntyre at
	 * http://www.cis.upenn.edu/~treebank/tokenizer.sed .
	 * </p>
	 * 
	 * @param text,
	 *            string to be prepared
	 * @return string ready to be split into tokens.
	 */
	public static String tokenize(String text) {
		text = text.toLowerCase();

		text = text.replaceAll("^\"", "`` ");
		text = text.replaceAll("``", " `` ");
		text = text.replaceAll("([ \\(\\[{<])\"", "$1 `` ");
		text = text.replaceAll("\\.\\.\\.", " ... ");
		text = text.replaceAll("[,;:@#\\$%&]", " $0 ");
		text = text.replaceAll("([^.])([.])([\\])}>\"']*)[ \t]*$", "$1 $2$3 ");
		text = text.replaceAll("[?!]", " $0 ");
		text = text.replaceAll("[\\]\\[\\(\\){}\\<\\>]", " $0 ");
		text = text.replaceAll("--", " -- ");
		text = text.replaceAll("$", " ");
		text = text.replaceAll("^", " ");
		text = text.replaceAll("\"", " '' ");
		text = text.replaceAll("''", " '' ");
		text = text.replaceAll("([^'])' ", "$1 ' ");
		text = text.replaceAll("'([sSmMdD]) ", " '$1 ");
		text = text.replaceAll("'ll ", " 'll ");
		text = text.replaceAll("'re ", " 're ");
		text = text.replaceAll("'ve ", " 've ");
		text = text.replaceAll("n't ", " n't ");
		text = text.replaceAll("'LL ", " 'LL ");
		text = text.replaceAll("'RE ", " 'RE ");
		text = text.replaceAll("'VE ", " 'VE ");
		text = text.replaceAll("N'T ", " N'T ");
		text = text.replaceAll(" ([Cc])annot ", " $1an not ");
		text = text.replaceAll(" ([Dd])'ye ", " $1' ye ");
		text = text.replaceAll(" ([Gg])imme ", " $1im me ");
		text = text.replaceAll(" ([Gg])onna ", " $1on na ");
		text = text.replaceAll(" ([Gg])otta ", " $1ot ta ");
		text = text.replaceAll(" ([Ll])emme ", " $1em me ");
		text = text.replaceAll(" ([Mm])ore'n ", " $1ore 'n ");
		text = text.replaceAll(" '([Tt])is ", " '$1 is ");
		text = text.replaceAll(" '([Tt])was ", " '$1 was ");
		text = text.replaceAll(" ([Ww])anna ", " $1an na ");
		text = text.replaceAll("  *", " ");
		text = text.replaceAll("^ *", "");

		return text;
	}

	public static String stem(String text) {
		Stemmer st = new Stemmer();
		char[] ar = text.toLowerCase().toCharArray();
		st.add(ar, ar.length);
		st.stem();
		String result = st.toString();
		return result;
	}

	private String treeNodeToText(List<TreeNode> arg1TreeNodes) {
		StringBuilder sb = new StringBuilder();
		for (TreeNode node : arg1TreeNodes) {
			List<Tree> posNodes = new ArrayList<>();
			getAllPosNodes(node.getRoot(), posNodes);
			String sent = Corpus.nodesToString(posNodes);
			sb.append(sent);
		}

		return sb.toString();
	}

	@Override
	public File parseAnyText(File modelFile, File inputFile) throws IOException {

		String filePath = TMP_PATH + inputFile.getName() + "." + NAME;
		File testFile = new File(filePath);

		PrintWriter featureFile = new PrintWriter(testFile);

		List<String[]> features = generateEpFeatures(inputFile, FeatureType.AnyText);
		for (String[] feature : features) {
			featureFile.println(feature[0]);
		}

		featureFile.close();
		File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(filePath + ".out"));

		File resultFile = new File(filePath + ".res");

		try (PrintWriter pw = new PrintWriter(resultFile); BufferedReader read = Util.reader(outFile)) {
			for (String[] feature : features) {
				String[] tmp = read.readLine().split("\\s+");
				String[] cols = feature[1].split("\\|", -1);
				String fullSense = Corpus.getFullSense(tmp[tmp.length - 1]);
				if (fullSense.equals("EntRel") || fullSense.equals("AltLex")) {
					feature[1] = feature[1].replaceAll("Implicit\\|", fullSense + "|");
					pw.println(feature[1]);
				} else {
					StringBuilder sb = new StringBuilder();
					for (int i = 0; i < 48; ++i) {
						sb.append((i == 11) ? fullSense : cols[i]);
						sb.append("|");
					}
					sb.deleteCharAt(sb.length() - 1);
					pw.println(sb.toString());
				}
			}
		}

		return resultFile;
	}

	protected HashMap<String, Dependency> getDtreeMap() {
		return this.dtreeMap;
	}
}
