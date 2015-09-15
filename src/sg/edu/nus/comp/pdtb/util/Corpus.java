/**
 * Copyright (C) 2014-2015 WING, NUS and NUS NLP Group.
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

package sg.edu.nus.comp.pdtb.util;

import static sg.edu.nus.comp.pdtb.util.Settings.PTB_AUTO_TREE_PATH;
import static sg.edu.nus.comp.pdtb.util.Settings.PTB_TREE_PATH;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import edu.stanford.nlp.trees.LabeledScoredTreeFactory;
import edu.stanford.nlp.trees.PennTreeReader;
import edu.stanford.nlp.trees.Tree;
import edu.stanford.nlp.trees.TreeReader;

public class Corpus {

	private static final Logger log = LogManager.getLogger(Corpus.class.getName());

	public static List<Tree> getNonExpTrees(File article, FeatureType featureType) throws IOException {

		String path = "";
		if (featureType == FeatureType.Auto) {
			StringBuilder sb = new StringBuilder();
			sb.append(Settings.PTB_NONEXP_TREES_PATH);
			sb.append(article.getName().substring(4, 6));
			sb.append("/");
			sb.append(article.getName().substring(0, 8));
			sb.append(".mrg");
			path = sb.toString();
		} else if (featureType == FeatureType.AnyText) {
			path = Settings.TMP_PATH + article.getName() + ".ptree";
		} else {
			path = genTreePath(article, featureType) + ".mrg";
		}

		List<Tree> trees = new ArrayList<>();
		Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(path), Util.ENCODING));
		try (TreeReader tr = new PennTreeReader(r, new LabeledScoredTreeFactory())) {
			Tree t = tr.readTree();
			while (t != null) {
				trees.add(t);
				t = tr.readTree();
			}
		}

		return trees;
	}

	public static List<Tree> getTrees(File article, FeatureType featureType) throws IOException {

		String path;
		if (featureType == FeatureType.AnyText) {
			path = Settings.TMP_PATH + article.getName() + ".ptree";
		} else {
			path = genTreePath(article, featureType) + ".mrg";
		}

		List<Tree> trees = new ArrayList<>();
		Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(path), Util.ENCODING));
		try (TreeReader tr = new PennTreeReader(r, new LabeledScoredTreeFactory())) {
			Tree t = tr.readTree();
			while (t != null) {
				trees.add(t);
				t = tr.readTree();
			}
		}

		return trees;
	}

	public static File[] getSectionFiles(int section) {

		String folder = String.format("%02d/", section);
		File[] files = new File(Settings.PDTB_PATH + folder).listFiles(new FilenameFilter() {
			@Override
			public boolean accept(File dir, String name) {
				return name.endsWith("pipe");
			}
		});

		return files;
	}

	private static String genTreePath(File article, FeatureType featureType) {

		StringBuilder path = new StringBuilder();
		path.append(featureType == FeatureType.Auto ? PTB_AUTO_TREE_PATH : PTB_TREE_PATH);
		path.append(article.getName().substring(4, 6));
		path.append("/");
		path.append(article.getName().substring(0, 8));

		return path.toString();
	}

	private static String genDependTreePath(File article, FeatureType featureType) {

		StringBuilder path = new StringBuilder();
		if (featureType == FeatureType.Auto) {
			path.append(Settings.DEPEND_AUTO_TREE_PATH);
		} else {
			path.append(Settings.DEPEND_TREE_PATH);
		}
		path.append(article.getName().substring(4, 6));
		path.append('/');
		path.append(article.getName().substring(0, 8));
		path.append(".dtree");

		return path.toString();
	}

	private static String genParaFilePath(File article) {

		StringBuilder path = new StringBuilder();
		path.append(Settings.PARA_PATH);
		path.append(article.getName().substring(4, 6));
		path.append('/');
		path.append(article.getName().substring(0, 8));
		path.append(".para");

		return path.toString();
	}

	public static List<String> getNonExplicitSpans(File article) throws IOException {

		String path = genPipePath(article);
		List<String> result = new ArrayList<>();

		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(path), Util.ENCODING))) {

			String line;
			while ((line = reader.readLine()) != null) {
				if (!line.startsWith("Explicit")) {
					result.add(line);
				}
			}
		}

		return result;
	}

	public static List<String> getExplicitSpans(File article, FeatureType featureType) throws IOException {

		if (featureType == FeatureType.AnyText) {
			return genExplicitSpans(article);
		}

		List<String> result = new ArrayList<>();
		String path = genPipePath(article);
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(path), Util.ENCODING))) {

			String line;
			while ((line = reader.readLine()) != null) {
				if (line.startsWith("Explicit")) {
					result.add(line);
				}
			}
		}
		return result;
	}

	public static List<String> getFilteredSpans(String articleFilename, FeatureType featureType) throws IOException {

		File article = new File(genPipePath(articleFilename));

		List<String> result = getExplicitSpans(article, featureType);
		result = filterErrorProp(result, article, featureType);

		return result;
	}

	private static List<String> genExplicitSpans(File article) throws IOException {
		File spans = new File(Settings.TMP_PATH + article.getName() + "." + ConnComp.NAME + ".spans");
		File outFile = new File(Settings.TMP_PATH + article.getName() + "." + ConnComp.NAME + ".out");
		List<String> result = new ArrayList<>();
		try (BufferedReader reader = Util.reader(spans); BufferedReader outReader = Util.reader(outFile)) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] out = outReader.readLine().split("\\s+");
				if (out[2].equals("1")) {
					String[] cols = line.split("\\s+");
					StringBuilder rel = new StringBuilder();
					rel.append("Explicit|");
					rel.append("||");
					rel.append(cols[0] + "|");// col 3 connective span
					rel.append("|");
					rel.append(cols[2].replace('_', ' ') + "|");// col 5
																// connective
																// raw text
					rel.append("|");
					rel.append(cols[1] + "|");// col 7 sentence number
					rel.append(cols[2].toLowerCase().replace('_', ' ') + "|"); // col
																				// 8
																				// connective
																				// head
					for (int i = 0; i < 38; ++i) {
						rel.append("|");
					}
					result.add(rel.toString());
				}
			}
		}

		return result;
	}

	public static List<String> filterErrorProp(List<String> explicitSpans, File article, FeatureType featureType)
			throws IOException {
		List<String> result = new ArrayList<>(explicitSpans.size());
		Set<String> epSpans = getEpSpans(article, featureType);

		for (String rel : explicitSpans) {

			String headSpan = calculateHeadSpan(rel);

			if (epSpans.contains(headSpan)) {
				result.add(rel);
			}
		}

		return result;
	}

	public static String calculateHeadSpan(String pipe) {
		String[] cols = pipe.split("\\|", -1);
		String head = cols[8];
		String rawText = cols[5].toLowerCase();
		String span = cols[3];
		if (!((cols[1] + cols[2]).equals("2369") && head.equals("if then"))) {

			int index = rawText.indexOf(head);
			int start = Integer.parseInt(span.split("\\.\\.")[0]) + index;
			int end = start + head.length();
			return start + ".." + end;
		} else {
			return span;
		}
	}

	private static Set<String> getEpSpans(File article, FeatureType featureType) throws IOException {

		String spansFile = Settings.OUT_PATH + ConnComp.NAME;
		String outFile = Settings.OUT_PATH + ConnComp.NAME;

		if (featureType == FeatureType.Auto) {
			spansFile += ".auto.ep.spans";
			outFile += ".auto.ep.out";
		} else {
			// TODO not sure if correct
			spansFile += ".gs.ep.spans";
			outFile += ".gs.ep.out";
		}

		Set<String> spans = new HashSet<>();

		try (BufferedReader spanReader = new BufferedReader(
				new InputStreamReader(new FileInputStream(spansFile), Util.ENCODING))) {

			try (BufferedReader outReader = new BufferedReader(
					new InputStreamReader(new FileInputStream(outFile), Util.ENCODING))) {
				String spanLine;
				while ((spanLine = spanReader.readLine()) != null) {
					// 39..42 1 But wsj_2300.pipe 1
					String[] tmp = spanLine.split("\\s+");
					String span = tmp[0];
					// 0[0.0792] 1[0.9208] 1
					String[] outLine = outReader.readLine().split("\\s+");
					boolean predictedConnUse = outLine[outLine.length - 1].equals("1");

					if (tmp[3].equals(article.getName()) && predictedConnUse) {
						spans.add(span);
					}
				}
			}
		}

		return spans;
	}

	private static String genPipePath(File article) {
		StringBuilder path = new StringBuilder();
		path.append(Settings.PDTB_PATH);
		path.append(article.getName().substring(4, 6));
		path.append("/");
		path.append(article.getName());

		return path.toString();
	}

	private static String genPipePath(String articleFilename) {
		StringBuilder path = new StringBuilder();
		path.append(Settings.PDTB_PATH);
		path.append(articleFilename.substring(4, 6));
		path.append("/");
		path.append(articleFilename + ".pipe");

		return path.toString();
	}

	public static String genEpP2ipePath(String articleFilename, FeatureType featureType) {
		StringBuilder path = new StringBuilder();
//		path.append(featureType == FeatureType.ErrorPropagation ? Settings.ARG_EXT_EP : Settings.ARG_EXT_AUTO);
		path.append(articleFilename + ".pipe");

		return path.toString();
	}

	public static Set<String> getExplicitSpansAsSet(File article, FeatureType featureType) {

		if (featureType == FeatureType.AnyText) {
			return null;
		}

		String filePath = genTreePath(article, FeatureType.GoldStandard) + ".hw";
		Set<String> result = new HashSet<>();

		try (Scanner sc = new Scanner(new File(filePath))) {
			while (sc.hasNextLine()) {
				String line = sc.nextLine();
				String[] cols = line.split(",");
				String[] span = cols[0].split(";");
				for (int i = 0; i < span.length; ++i) {
					result.add(span[i]);
				}
			}
		} catch (FileNotFoundException e) {
			// there is no explicit span, so continue and return empty set.
		}

		return result;
	}

	public static Map<String, String> getSpanMap(File article, FeatureType featureType) throws IOException {

		String filePath;
		if (featureType == FeatureType.AnyText) {
			filePath = Settings.TMP_PATH + article.getName() + ".ptree.csv";
		} else {
			filePath = genTreePath(article, featureType) + ".csv";
		}
		Map<String, String> result = new HashMap<>();
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(filePath), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] cols = line.split(",", -1);
				String key = cols[1] + ":" + cols[2];
				String value = cols[3];
				if (result.containsKey(key)) {
					log.error("Duplicate span (" + key + ") in file: " + filePath);
				}
				result.put(key, value);
			}
		}

		return result;
	}

	public static ArrayList<String> getSpanMapAsList(File article, FeatureType featureType) throws IOException {

		String filePath;
		if (featureType == FeatureType.AnyText) {
			filePath = Settings.TMP_PATH + article.getName() + ".ptree.csv";
		} else {
			filePath = genTreePath(article, featureType) + ".csv";
		}

		ArrayList<String> result = new ArrayList<>();
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(filePath), Util.ENCODING))) {

			String line;
			while ((line = reader.readLine()) != null) {
				result.add(line);
			}
		}

		return result;
	}

	public static String getLabel(String arg1Gorn, String arg2Gorn) {

		LinkedList<Integer> arg1 = gornToSenIds(arg1Gorn);
		LinkedList<Integer> arg2 = gornToSenIds(arg2Gorn);
		String label = "";

		if (arg1.getLast() + 1 == arg2.getFirst()) {
			label = "IPS";
		} else if (arg1.getLast() + 1 < arg2.getFirst()) {
			label = "NAPS";
		} else if (arg2.getFirst() + 1 <= arg1.getFirst()) {
			label = "FS";
		} else {
			label = "SS";
		}

		return label;
	}

	private static LinkedList<Integer> gornToSenIds(String gorn) {
		String[] tmp = gorn.split(";");
		LinkedList<Integer> res = new LinkedList<>();
		Set<Integer> done = new HashSet<>();
		for (String t : tmp) {
			String[] e = t.split(",");
			int i = Integer.parseInt(e[0]);
			if (!done.contains(i)) {
				res.add(i);
				done.add(i);
			}
		}

		return res;
	}

	public static String[] getDependTrees(File article, FeatureType featureType) throws IOException {
		String dtreeFilePath = "";
		if (featureType == FeatureType.AnyText) {
			dtreeFilePath = Settings.TMP_PATH + article.getName() + ".dtree";
		} else {
			dtreeFilePath = genDependTreePath(article, featureType);
		}
		String[] dtreeTexts = Util.readFile(dtreeFilePath).split("\\n\\n");
		return dtreeTexts;
	}

	public static int[] getParagraphs(File article, FeatureType featureType) throws IOException {
		if (featureType == FeatureType.AnyText) {
			return genParagraphIndices(article, featureType);
		} else {

			String paraFilePath = genParaFilePath(article);

			String[] texts = Util.readFile(paraFilePath).split("\\n+");
			int[] result = new int[texts.length];

			for (int i = 0; i < texts.length; i++) {
				String string = texts[i];
				result[i] = Integer.parseInt(string);
			}
			return result;
		}
	}

	private static int[] genParagraphIndices(File article, FeatureType featureType) throws IOException {
		String[] orgText = Util.readFile(article).replaceAll("`", "'").split("\\n");
		List<Integer> tmp = new ArrayList<>();
		int index = 0;
		for (String sent : orgText) {
			if (sent.isEmpty()) {
				tmp.add(index - tmp.size());
			}
			++index;
		}
		int[] result = new int[tmp.size() + 1];
		result[0] = 0;
		for (int i = 1; i < result.length; ++i) {
			result[i] = tmp.get(i - 1);
		}

		return result;
	}

	public static Map<String, String> getSentMap(File article) throws IOException {

		StringBuilder path = new StringBuilder();

		path.append(Settings.SENT_MAP_PATH);
		path.append(article.getName().substring(4, 6));
		path.append("/");
		path.append(article.getName().substring(0, 8));
		path.append(".align");

		Map<String, String> result = new HashMap<>();
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(path.toString()), Util.ENCODING))) {
			String line;
			while ((line = reader.readLine()) != null) {
				String[] vals = line.split("\\s+");
				result.put(vals[0], vals[1]);
			}
		}
		return result;
	}

	public static String getFullSense(String predictedSense) {
		String level1Sense = "";
		String level2Sense = predictedSense;
		switch (predictedSense) {
		case "Asynchronous":
		case "Synchrony":
			level1Sense = "Temporal.";
			break;
		case "Contrast":
		case "Pragmatic_contrast":
		case "Concession":
		case "Pragmatic_concession":
			level1Sense = "Comparison.";
			break;
		case "Conjunction":
		case "Instantiation":
		case "Restatement":
		case "Alternative":
		case "Exception":
		case "List":
			level1Sense = "Expansion.";
			break;
		case "Cause":
		case "Pragmatic_cause":
		case "Condition":
		case "Pragmatic_condition":
			level1Sense = "Contingency.";
			break;
		case "EntRel":
		case "AltLex":
			level1Sense = predictedSense;
			level2Sense = "";
			break;
		}
		return (level1Sense + level2Sense).replace('_', ' ');
	}

	public static String spanToText(String span, String orgText) {
		if (span.isEmpty()) {
			return "";
		} else {
			int[] sp = spanToInt(span);
			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < sp.length; i += 2) {
				String text = orgText.substring(sp[i], sp[i + 1]).replaceAll("\\r", "").replaceAll(Util.NEW_LINE, "");
				sb.append(text.trim() + " ");
			}
			return sb.toString().trim();
		}
	}

	public static int[] spanToInt(String span) {
		if (span.trim().length() > 0) {
			String[] sp = span.split(";");
			int[] result = new int[sp.length * 2];
			for (int i = 0; i < sp.length; ++i) {
				Integer start = Integer.parseInt(sp[i].substring(0, sp[i].indexOf('.')));
				Integer end = Integer.parseInt(sp[i].substring(sp[i].lastIndexOf('.') + 1));
				result[i * 2] = start;
				result[i * 2 + 1] = end;
			}
			return result;
		} else {
			return null;
		}
	}

	public static String nodeToString(Tree leaf) {
		String leafStr = leaf.toString();
		leafStr = leafStr.replaceAll("-LRB-", "(");
		leafStr = leafStr.replaceAll("-LCB-", "{");
		leafStr = leafStr.replaceAll("-RRB-", ")");
		leafStr = leafStr.replaceAll("-RCB-", "}");
		leafStr = leafStr.replaceAll("``", "\"");
		leafStr = leafStr.replaceAll("''", "\"");
		return leafStr;
	}

	public static String nodesToString(List<Tree> posNodes) {
		StringBuilder sba = new StringBuilder();
		for (Tree leaf : posNodes) {
			sba.append(Corpus.nodeToString(leaf.firstChild()));
			sba.append(' ');
		}
		return sba.toString().trim();
	}

}
