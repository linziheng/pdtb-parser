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
import static sg.edu.nus.comp.pdtb.util.Settings.MODEL_PATH;
import static sg.edu.nus.comp.pdtb.util.Settings.OUTPUT_FOLDER_NAME;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import edu.stanford.nlp.ling.HasWord;
import edu.stanford.nlp.parser.lexparser.LexicalizedParser;
import edu.stanford.nlp.process.DocumentPreprocessor;
import edu.stanford.nlp.trees.LabeledScoredTreeFactory;
import edu.stanford.nlp.trees.PennTreeReader;
import edu.stanford.nlp.trees.Tree;
import edu.stanford.nlp.trees.TreePrint;
import edu.stanford.nlp.trees.TreeReader;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

public class Corpus {

	public static enum Type {
		PDTB, BIO_DRB;
	}

	public static FilenameFilter PIPE_FILTER = new FilenameFilter() {
		@Override
		public boolean accept(File dir, String name) {
			return name.endsWith(".pipe");
		}
	};

	public static FilenameFilter TXT_FILTER = new FilenameFilter() {
		@Override
		public boolean accept(File dir, String name) {
			return name.endsWith(".txt");
		}
	};

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
			path = OUTPUT_FOLDER_NAME + article.getName() + ".ptree";
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
			path = OUTPUT_FOLDER_NAME + article.getName() + ".ptree";
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

	public static List<Tree> getBioTrees(File article, FeatureType featureType) throws IOException {
		String path;
		if (featureType == FeatureType.AnyText) {
			path = OUTPUT_FOLDER_NAME + article.getName() + ".ptree";
		} else {
			path = Settings.BIO_DRB_TREE_PATH + article.getName() + ".ptree";
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

	public static List<String> getBioNonExplicitSpans(File article) throws IOException {
		String path = Settings.BIO_DRB_ANN_PATH + article.getName();
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

	public static List<String> getBioExplicitSpans(File article, FeatureType featureType) throws IOException {
		if (featureType == FeatureType.AnyText) {
			return genBioExplicitSpans(article);
		}

		List<String> result = new ArrayList<>();
		String path = Settings.BIO_DRB_ANN_PATH + article.getName();

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

	private static List<String> genBioExplicitSpans(File article) {
		// TODO Auto-generated method stub
		throw new NotImplementedException();
	}

	public static List<String> getFilteredSpans(String articleFilename, FeatureType featureType) throws IOException {

		File article = new File(genPipePath(articleFilename));

		List<String> result = getExplicitSpans(article, featureType);
		result = filterErrorProp(result, article, featureType);

		return result;
	}

	private static List<String> genExplicitSpans(File article) throws IOException {
		File spans = new File(OUTPUT_FOLDER_NAME + article.getName() + "." + ConnComp.NAME + ".spans");
		File outFile = new File(OUTPUT_FOLDER_NAME + article.getName() + "." + ConnComp.NAME + ".out");
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

	public static List<String> filterBioErrorProp(List<String> explicitSpans, File article, FeatureType featureType)
			throws IOException {
		List<String> result = new ArrayList<>(explicitSpans.size());
		Set<String> epSpans = getEpSpans(article, featureType);

		for (String rel : explicitSpans) {

			String connectiveSpan = rel.split("\\|", -1)[1];

			if (epSpans.contains(connectiveSpan)) {
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

		String spansFile = MODEL_PATH + ConnComp.NAME;
		String outFile = MODEL_PATH + ConnComp.NAME;

		if (featureType == FeatureType.Auto) {
			spansFile += ".auto.ep.spans";
			outFile += ".auto.ep.out";
		} else {
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
					// TODO check if this works with PDTB too.
					boolean actualConnUse = tmp[tmp.length - 1].equals("1");

					if (tmp[3].equals(article.getName()) && predictedConnUse && actualConnUse) {
						spans.add(span);
					}
				}
			}
		}

		return spans;
	}

	public static String genRawTextPath(File article) {
		StringBuilder path = new StringBuilder();
		path.append(Settings.PTB_RAW_PATH);
		path.append(article.getName().substring(4, 6));
		path.append("/");
		path.append(article.getName().substring(0, 8));

		return path.toString();
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

	public static Set<String> getBioExplicitSpansAsSet(File article, FeatureType featureType) throws IOException {
		if (featureType == FeatureType.AnyText) {
			return null;
		}

		String filePath = Settings.BIO_DRB_TREE_PATH + article.getName() + ".hw";
		Set<String> result = new HashSet<>();

		try (BufferedReader reader = Util.reader(filePath)) {
			String line;
			while ((line = reader.readLine()) != null) {
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
			filePath = OUTPUT_FOLDER_NAME + article.getName() + ".ptree.csv";
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

	/**
	 * returns map with:<br>
	 * - key= treeNumber:treeNode_number<br>
	 * - value= span
	 * 
	 * @param article
	 * @param featureType
	 * @return
	 * @throws IOException
	 */
	public static Map<String, String> getBioSpanMap(File article, FeatureType featureType) throws IOException {

		String filePath;
		if (featureType == FeatureType.AnyText) {
			filePath = OUTPUT_FOLDER_NAME + article.getName() + ".ptree.csv";
		} else {
			filePath = Settings.BIO_DRB_TREE_PATH + article.getName() + ".ptree.csv";
		}
		Map<String, String> result = new HashMap<>();
		try (BufferedReader reader = new BufferedReader(
				new InputStreamReader(new FileInputStream(filePath), Util.ENCODING))) {
			String line;
			// file name, treeNumber, treeNode number, span, word
			// 1064873.txt.ptree,0,6,0..10,Resistance
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
			filePath = OUTPUT_FOLDER_NAME + article.getName() + ".ptree.csv";
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

	public static ArrayList<String> getBioSpanMapAsList(File article, FeatureType featureType) throws IOException {
		String filePath;
		if (featureType == FeatureType.AnyText) {
			filePath = OUTPUT_FOLDER_NAME + article.getName() + ".ptree.csv";
		} else {
			filePath = Settings.BIO_DRB_TREE_PATH + article.getName() + ".ptree.csv";
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

	public static String getBioLabel(String arg1Span, String arg2Span, ArrayList<String> spanMap) throws IOException {
		LinkedList<Integer> arg1 = spanToSenIds(arg1Span, spanMap);
		LinkedList<Integer> arg2 = spanToSenIds(arg2Span, spanMap);

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

	public static LinkedList<Integer> spanToSenIds(String span, ArrayList<String> spanMap) throws IOException {

		LinkedList<Integer> result = new LinkedList<>();
		String[] spans = span.split(";");
		for (String line : spanMap) {
			// 1064873.txt.ptree,0,6,0..10,Resistance
			String[] cols = line.split(",", -1);

			int start = Integer.parseInt(cols[3].split("\\.\\.")[0]);
			int end = Integer.parseInt(cols[3].split("\\.\\.")[1]);

			for (String tmp : spans) {
				int outStart = Integer.parseInt(tmp.split("\\.\\.")[0]);
				int outEnd = Integer.parseInt(tmp.split("\\.\\.")[1]);
				if (outStart <= start && end <= outEnd) {
					result.add(Integer.parseInt(cols[1]));
				}
			}
		}

		Collections.sort(result);

		return result;
	}

	public static String[] getDependTrees(File article, FeatureType featureType) throws IOException {
		String dtreeFilePath = "";
		if (featureType == FeatureType.AnyText) {
			dtreeFilePath = OUTPUT_FOLDER_NAME + article.getName() + ".dtree";
		} else {
			dtreeFilePath = genDependTreePath(article, featureType);
		}
		String[] dtreeTexts = Util.readFile(dtreeFilePath).split("\\n\\n");
		List<String> result = new ArrayList<>(dtreeTexts.length);
		for (String text : dtreeTexts) {
			for (int i = 0; i < text.length() - 1; ++i) {
				if (text.charAt(i) == '\n' && !Character.isWhitespace(text.charAt(i + 1))) {
					result.add("");
				} else {
					break;
				}
			}
			result.add(text);
		}

		return result.toArray(new String[result.size()]);

	}

	public static String[] getBioDependTrees(File article, FeatureType featureType) throws IOException {
		String dtreeFilePath = "";
		if (featureType == FeatureType.AnyText) {
			dtreeFilePath = OUTPUT_FOLDER_NAME + article.getName() + ".dtree";
		} else {
			dtreeFilePath = Settings.BIO_DRB_TREE_PATH + article.getName() + ".dtree";
		}
		String[] dtreeTexts = Util.readFile(dtreeFilePath).split("\\n\\n");
		return dtreeTexts;
	}

	public static int[] getParagraphs(File article, List<String> map, FeatureType featureType) throws IOException {
		return getParagraphs(Type.PDTB, article, map, featureType);
	}

	public static int[] getParagraphs(Type corpus, File article, List<String> map, FeatureType featureType)
			throws IOException {
		if (featureType == FeatureType.AnyText || corpus.equals(Type.BIO_DRB)) {
			return genParagraphIndices(article, map);
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

	private static int[] genParagraphIndices(File article, List<String> spanList) throws IOException {
		String orgText = Util.readFile(article).replaceAll("`", "'").replace('\r', '\n');

		String paragraphSeparator = "\n\n";

		Set<Integer> paragraphs = new TreeSet<>();
		int location = orgText.indexOf(paragraphSeparator);
		int index = 0;
		for (; location != -1 && index < spanList.size(); ++index) {
			// file name, treeNumber, treeNode number, span, word
			// 1064873.txt.ptree,0,6,0..10,Resistance
			String[] line = spanList.get(index).split(",");
			int[] span = spanToInt(line[3]);
			int diff1 = Math.abs(span[0] - location);
			int diff2 = Math.abs(span[1] - location);
			if (diff1 < 2 || diff2 < 2) {
				paragraphs.add(Integer.parseInt(line[1]));
				location = orgText.indexOf(paragraphSeparator, location + 1);
			}
		}
		int[] result = new int[paragraphs.size()];
		int i = 0;
		for (Integer paragraphIndex : paragraphs) {
			result[i] = paragraphIndex;
			++i;
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

	public static String continuousTextToSpan(String contText, String sourceText) {

		sourceText = sourceText.replace(' ', ' ');
		sourceText = sourceText.replaceAll("[^\\p{ASCII}]", "&");
		contText = contText.replaceAll("[^\\p{ASCII}]", "&");
		int newSourceLength = sourceText.replaceAll("\\s+", "").length();
		StringBuilder sb = new StringBuilder(newSourceLength);
		int[] mapNewToOld = new int[newSourceLength];

		for (int i = 0; i < sourceText.length(); ++i) {
			char sourceChar = sourceText.charAt(i);
			if (!Character.isWhitespace(sourceChar)) {
				mapNewToOld[sb.length()] = i;
				sb.append(sourceChar);
			}
		}

		String newSource = sb.toString();
		if (newSource.length() != newSourceLength) {
			log.error("Missed some whitespace");
		}

		String newContText = contText.replaceAll("\\s+", "");
		int chop = Math.min(newContText.length(), 19);
		int start = newSource.indexOf(newContText.substring(0, chop));
		int end = Math.min(start + newContText.length() - 1, mapNewToOld.length - 1);
		if (start == -1) {
			return "";
		} else {
			int realStart = mapNewToOld[start];
			int realEnd = mapNewToOld[end];

			return realStart + ".." + realEnd;
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
		leafStr = leafStr.replaceAll("-LSB-", "[");
		leafStr = leafStr.replaceAll("-RRB-", ")");
		leafStr = leafStr.replaceAll("-RCB-", "}");
		leafStr = leafStr.replaceAll("-RSB-", "]");
		leafStr = leafStr.replaceAll("``", "\"");
		leafStr = leafStr.replaceAll("''", "\"");
		leafStr = leafStr.replaceAll("--", "–");
		leafStr = leafStr.replaceAll("`", "'");

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

	public static File[][] prepareParseAndDependecyTrees(File[] inputFiles) throws FileNotFoundException {
		return prepareParseAndDependecyTrees(inputFiles, OUTPUT_FOLDER_NAME);
	}

	public static File[][] prepareParseAndDependecyTrees(File[] inputFiles, String outPath)
			throws FileNotFoundException {
		log.info("Generating parse and dependecy trees with Stanford parser...");

		File[][] trees = new File[inputFiles.length][2];
		int index = 0;
		LexicalizedParser lp = LexicalizedParser.loadModel(Settings.STANFORD_MODEL);
		for (File inputFile : inputFiles) {
			log.info("Generating tree for: " + inputFile.getName());
			String outDir = outPath + inputFile.getName();
			File parseTree = new File(outDir + ".ptree");
			File dependTree = new File(outDir + ".dtree");
			PrintWriter parse = new PrintWriter(parseTree);
			TreePrint tp = new TreePrint("penn");
			PrintWriter depend = new PrintWriter(dependTree);
			TreePrint td = new TreePrint("typedDependencies");

			DocumentPreprocessor sentence = new DocumentPreprocessor(inputFile.toString());
			int lineNumber = 0;
			for (List<HasWord> sent : sentence) {
				log.info("Parsing line:" + lineNumber);
				log.trace("Parsing: " + sent);
				Tree tree = lp.apply(sent);

				tp.printTree(tree, parse);
				parse.flush();

				td.printTree(tree, depend);
				depend.flush();
				++lineNumber;
			}
			parse.close();
			depend.close();
			log.info("Tree generation for " + inputFile.getName() + " is done. Trees are in " + outDir);

			trees[index] = new File[] { parseTree, dependTree };
			index++;
		}

		return trees;
	}

	public static Map<String, LinkedList<Integer>> getBioSpanToSenId(ArrayList<String> spanMap,
			List<String> relations) {
		Map<String, LinkedList<Integer>> spanToSenIdMap = new HashMap<>();

		for (String rel : relations) {
			String[] cols = rel.split("\\|", -1);
			String[] argSpans = { cols[14], cols[20] };

			for (String line : spanMap) {
				// 1064873.txt.ptree,0,6,0..10,Resistance
				String[] lineCols = line.split(",", -1);

				int start = Integer.parseInt(lineCols[3].split("\\.\\.")[0]);
				int end = Integer.parseInt(lineCols[3].split("\\.\\.")[1]);

				for (String span : argSpans) {
					if (span.length() > 0) {
						LinkedList<Integer> result = new LinkedList<>();
						String[] spans = span.split(";");
						for (String tmp : spans) {
							int outStart = Integer.parseInt(tmp.split("\\.\\.")[0]);
							int outEnd = Integer.parseInt(tmp.split("\\.\\.")[1]);

							if (outStart <= start && end <= outEnd) {
								result.add(Integer.parseInt(lineCols[1]));
							}
						}
						if (result.size() > 0) {
							Collections.sort(result);
							spanToSenIdMap.put(span, result);
						}
					}
				}
			}
		}
		return spanToSenIdMap;
	}

}
