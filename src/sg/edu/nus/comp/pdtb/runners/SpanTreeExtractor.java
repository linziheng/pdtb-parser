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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Reader;
import java.util.HashMap;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import edu.stanford.nlp.trees.LabeledScoredTreeFactory;
import edu.stanford.nlp.trees.PennTreeReader;
import edu.stanford.nlp.trees.Tree;
import edu.stanford.nlp.trees.TreeFactory;
import edu.stanford.nlp.trees.TreeReader;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

public class SpanTreeExtractor {

	private static Logger log = LogManager.getLogger(SpanTreeExtractor.class.getName());

	public static void main(String[] args) throws IOException {

		expSpansGen(Settings.PTB_TREE_PATH, Settings.PDTB_PATH);
		textToSpanGen(Settings.PTB_TREE_PATH, Settings.PTB_RAW_PATH);
	}

	public static void createPdtbDependTrees(String ptbTextDir, String ptbDependOutDir) throws FileNotFoundException {
		File[] folders = new File(ptbTextDir).listFiles();
		for (File folder : folders) {
			if (folder.isDirectory()) {
				String outDir = ptbDependOutDir + folder.getName() + "/";
				new File(outDir).mkdirs();
				File[] files = folder.listFiles();
				Corpus.prepareParseAndDependecyTrees(files, outDir);
			}
		}
	}

	public static void textToSpanSharedTask(String treePath) throws IOException {
		log.info("Generating the spans of each node in the parse trees.");
		String[] topFolders = new File(treePath).list(new FilenameFilter() {
			@Override
			public boolean accept(File dir, String name) {
				return new File(dir, name).isDirectory();
			}
		});

		for (String topFolder : topFolders) {
			String folder = topFolder + "/";
			File tmp = new File(treePath + folder);
			if (tmp.isDirectory() && tmp.exists()) {
				File[] files = tmp.listFiles(new FilenameFilter() {
					@Override
					public boolean accept(File dir, String name) {
						return name.endsWith("mrg");
					}
				});
				for (File file : files) {
					String fileName = file.getName().replaceAll("\\.mrg", "");
					log.info("Extracting spans in: " + fileName);
					sharedTaskSpanGen(file);
				}
			}
		}

	}

	private static void sharedTaskSpanGen(File treeFile) throws IOException {
		TreeFactory tf = new LabeledScoredTreeFactory();
		Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(treeFile), Util.ENCODING));
		TreeReader tr = new PennTreeReader(r, tf);
		Tree root = tr.readTree();
		String article = treeFile.getName().substring(0, 8);
		String outFileName = treeFile.toString();
		outFileName = outFileName.substring(0, outFileName.lastIndexOf('.'));
		BufferedReader reader = Util.reader(outFileName + ".tkn");
		PrintWriter printer = new PrintWriter(outFileName + ".csv");
		int treeNumber = 0;
		while (root != null) {
			String lineRead = reader.readLine();
			if (root.children().length > 0) {
				List<Tree> leaves = root.getLeaves();
				HashMap<String, String[]> tokens = sharedTaskTokens(lineRead);
				for (Tree leaf : leaves) {
					int nodeNumber = leaf.nodeNumber(root);
					String word = leaf.toString();
					String wordKey = word.replaceAll("/", "\\\\/");
					wordKey = wordKey.replaceAll("\\*", "\\\\*");
					String[] spanLine = tokens.get(wordKey);

					String key = article + "," + treeNumber + "," + nodeNumber;
					word = word.trim().replaceAll("\\s+", "");
					word = word.replaceAll(",", "COMMA");
					printer.println(key + "," + spanLine[1] + "," + word + "," + spanLine[2]);

				}
			}
			root = tr.readTree();
			printer.flush();
			++treeNumber;
		}
		printer.close();
		tr.close();
	}

	private static HashMap<String, String[]> sharedTaskTokens(String tknLine) {

		HashMap<String, String[]> map = new HashMap<>();

		String[] words = tknLine.split("#&#&#&");
		for (String wordLine : words) {
			String[] tmp = wordLine.split("T&T&T&");
			map.put(tmp[0], tmp);
		}
		return map;
	}

	public static void anyTextToSpanGen(File treeFile, File inputFile) throws IOException {
		log.info("Generating the spans of each node in the parse trees.");

		String orgText = Util.readFile(inputFile);
		orgText = orgText.replaceAll("`", "'").replaceAll("“", "\"");
		PrintWriter pw = new PrintWriter(treeFile + ".csv");
		TreeFactory tf = new LabeledScoredTreeFactory();
		Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(treeFile), Util.ENCODING));
		TreeReader tr = new PennTreeReader(r, tf);
		int index = 0;
		Tree root = tr.readTree();
		int treeNumber = 0;
		while (root != null) {

			List<Tree> leaves = root.getLeaves();

			for (Tree leaf : leaves) {
				int nodeNumber = leaf.nodeNumber(root);
				String parentValue = leaf.parent(root).value();
				if (parentValue.equals("-NONE-")) {
					continue;
				}
				String word = nodeToString(leaf).trim();
				word = word.replaceAll("`", "'");
				word = word.replaceAll("\\.\\.\\.", ". . .");
				int span = orgText.indexOf(word, index);
				if (span == -1) {
					continue;
				}
				index = span + word.length() - 1;
				String spanString = (span + ".." + (span + word.length()));
				String key = treeFile.getName() + "," + treeNumber + "," + nodeNumber;
				word = word.trim().replaceAll("\\s+", "");
				word = word.replaceAll(",", "COMMA");
				pw.println(key + "," + spanString + "," + word);
			}
			root = tr.readTree();
			pw.flush();
			++treeNumber;
		}
		pw.close();
		tr.close();

		log.info("Done.");
	}

	private static String nodeToString(Tree leaf) {
		String leafStr = leaf.toString();
		leafStr = leafStr.replaceAll("-LRB-", "(");
		leafStr = leafStr.replaceAll("-LCB-", "{");
		leafStr = leafStr.replaceAll("-LSB-", "[");
		leafStr = leafStr.replaceAll("-RRB-", ")");
		leafStr = leafStr.replaceAll("-RCB-", "}");
		leafStr = leafStr.replaceAll("-RSB-", "]");

		return leafStr;
	}

	/**
	 * Generate the .hw aux files that contain the explicit spans.
	 * 
	 * @param treePath
	 * @param pdtbPath
	 * @throws IOException
	 */
	public static void expSpansGen(String treePath, String pdtbPath) throws IOException {
		log.info("Generating the .hw aux files that contain the explicit spans.");
		String[] topFolders = new File(treePath).list(new FilenameFilter() {
			@Override
			public boolean accept(File dir, String name) {
				return new File(dir, name).isDirectory();
			}
		});

		for (String topFolder : topFolders) {
			String folder = topFolder + "/";
			File[] files = new File(pdtbPath + folder).listFiles(new FilenameFilter() {
				@Override
				public boolean accept(File dir, String name) {
					return name.startsWith("wsj_");
				}
			});
			String out = treePath + folder;
			for (File file : files) {
				String fileName = folder + file.getName();
				String article = file.getName().split("\\.")[0];

				PrintWriter pw = new PrintWriter(out + article + ".hw");
				try (BufferedReader reader = new BufferedReader(
						new InputStreamReader(new FileInputStream(pdtbPath + fileName), Util.ENCODING))) {
					String line;
					while ((line = reader.readLine()) != null) {
						String[] columns = line.split("\\|", -1);
						if (columns[0].equalsIgnoreCase("Explicit")) {
							String span = columns[3];
							String rawText = columns[5];
							String head = columns[8];
							if (rawText.equalsIgnoreCase(head)) {
								pw.println(span + "," + rawText + "," + head);
							} else {
								int index = rawText.indexOf(head);
								int start = Integer.parseInt(span.split("\\.\\.")[0]);
								int end = Integer.parseInt(span.split("\\.\\.")[1]);
								start += index;
								end = start + head.length();
								span = start + ".." + end;
								pw.println(span + "," + rawText + "," + head);
							}
						}
					}
				}
				pw.close();
			}
		}

		log.info("Done.");
	}

	public static void expBioSpansGen() throws IOException {

		log.info("Generating the .hw aux files that contain the explicit spans.");

		File[] pipes = new File(Settings.BIO_DRB_ANN_PATH).listFiles(Corpus.TXT_FILTER);
		for (File pipe : pipes) {
			log.info("Procesing file: " + pipe.getName());

			String fileName = pipe.getName();
			String articleText = Util.readFile(Settings.BIO_DRB_RAW_PATH + pipe.getName());
			PrintWriter pw = new PrintWriter(Settings.BIO_DRB_TREE_PATH + fileName + ".hw");
			try (BufferedReader reader = new BufferedReader(
					new InputStreamReader(new FileInputStream(Settings.BIO_DRB_ANN_PATH + fileName), Util.ENCODING))) {
				String line;
				while ((line = reader.readLine()) != null) {
					String[] columns = line.split("\\|", -1);
					if (columns[0].equalsIgnoreCase("Explicit")) {
						String span = columns[1];
						String rawText = Corpus.spanToText(span, articleText);
						pw.println(span + "," + rawText + "," + rawText.toLowerCase());
					}
				}
			}
			pw.close();
		}

		log.info("Done.");
	}

	/**
	 * Generate the spans of each node in the auto parse trees.
	 * 
	 * @param treePath
	 * @param rawTextPath
	 * @throws IOException
	 */
	@SuppressWarnings("unused")
	public static void textToSpanGenAuto(String treePath, String rawTextPath) throws IOException {
		log.info("Generating the spans of each node in the auto parse trees.");
		String folder = "23/";
		File[] files = new File(treePath + folder).listFiles(new FilenameFilter() {

			@Override
			public boolean accept(File dir, String name) {
				return name.startsWith("wsj_") && name.endsWith(".mrg");
			}
		});

		for (File file : files) {

			String fileName = file.getName().replaceAll("\\.mrg", "");
			String orgText = Util.readFile(rawTextPath + folder + fileName);
			orgText = orgText.replaceAll("`", "'");

			PrintWriter pw = new PrintWriter(treePath + folder + fileName + ".csv");

			TreeFactory tf = new LabeledScoredTreeFactory();
			Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF-8"));
			TreeReader tr = new PennTreeReader(r, tf);

			int index = 9;

			Tree root = tr.readTree();
			int treeNumber = 0;

			while (root != null) {
				StringBuilder tmp = new StringBuilder();
				List<Tree> leaves = root.getLeaves();
				for (Tree leaf : leaves) {
					int nodeNumber = leaf.nodeNumber(root);
					String parentValue = leaf.parent(root).value();
					if (parentValue.equals("-NONE-")) {
						continue;
					}

					String word = Corpus.nodeToString(leaf).trim();

					if (word.equals(".")) {
						continue;
					}

					word = word.replaceAll("`", "'");

					word = word.replaceAll("^\\p{Punct}*", "");
					word = word.replaceAll("\\p{Punct}*$", "");

					if (fileName.equals("wsj_2300") && index == 1457 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2330") && index == 6344 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2351") && index == 1040 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2360") && index == 2066 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2369") && index == 6434 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2381") && index == 2399 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2386") && index == 3522 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2386") && index == 3647 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2387") && index == 1466 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2387") && index == 5389 && word.equals("n't")) {
						word = "'t";
					}
					if (fileName.equals("wsj_2397") && index == 1032 && word.equals("n't")) {
						word = "'t";
					}

					if (fileName.equals("wsj_2306") && index == 5692 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2308") && index == 2373 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2315") && index == 1056 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2321") && index == 1279 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2330") && index == 1563 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2345") && index == 1838 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2350") && index == 699 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2351") && index == 778 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2351") && index == 2391 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2363") && index == 2868 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2367") && index == 1379 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2376") && index == 6687 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2377") && index == 2464 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2379") && index == 4711 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2379") && index == 5174 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2381") && index == 565 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2387") && index == 5430 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2387") && index == 5779 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2394") && index == 179 && word.equals("will")) {
						word = "wo";
					}
					if (fileName.equals("wsj_2397") && index == 5243 && word.equals("will")) {
						word = "wo";
					}

					int span = orgText.indexOf(word, index);
					while (span == -1) {
						span = orgText.indexOf(word, index);

					}

					if (span - index > 1) {
						String difference = orgText.substring(index, span).trim();
						boolean isError = true;
						isError &= !difference.matches("(\\p{Punct}+\\s*)+") && difference.length() > 0;
						isError &= !difference.equals("�");

					}
					index = span + word.length();
					String spanString = (span + ".." + (span + word.length()));
					String key = fileName + "," + treeNumber + "," + nodeNumber;
					word = word.trim().replaceAll("\\s+", "");
					word = word.replaceAll(",", "COMMA");
					tmp.append(key + "," + spanString + "," + word);
					tmp.append('\n');
				}
				root = tr.readTree();
				pw.print(tmp);
				++treeNumber;
			}
			pw.close();
			tr.close();
		}

		log.info("Done.");
	}

	/**
	 * Generate the spans of each node in the parse trees.
	 * 
	 * @param treePath
	 * @param rawTextPath
	 * @throws IOException
	 */
	@SuppressWarnings("unused")
	public static void textToSpanGen(String treePath, String rawTextPath) throws IOException {
		log.info("Generating the spans of each node in the parse trees.");
		String[] topFolders = new File(treePath).list(new FilenameFilter() {
			@Override
			public boolean accept(File dir, String name) {
				return new File(dir, name).isDirectory();
			}
		});

		for (String topFolder : topFolders) {
			String folder = topFolder + "/";
			File tmp = new File(treePath + folder);
			if (tmp.isDirectory() && tmp.exists()) {
				File[] files = tmp.listFiles(new FilenameFilter() {
					@Override
					public boolean accept(File dir, String name) {
						return name.endsWith("mrg");
					}
				});
				for (File file : files) {
					log.info("Processing tree: " + file.getName());
					String fileName = file.getName().replaceAll("\\.mrg", "");

					String orgText = Util.readFile(rawTextPath + folder + fileName);
					orgText = orgText.replaceAll("`", "'");

					PrintWriter pw = new PrintWriter(treePath + folder + fileName + ".csv");

					TreeFactory tf = new LabeledScoredTreeFactory();
					Reader r = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF-8"));
					TreeReader tr = new PennTreeReader(r, tf);

					int index = 9;

					if (fileName.equals("wsj_0285")) {
						index = 200;
					}
					if (fileName.equals("wsj_0901")) {
						index = 14;
					}

					Tree root = tr.readTree();
					int treeNumber = 0;

					while (root != null) {

						List<Tree> leaves = root.getLeaves();

						for (Tree leaf : leaves) {
							int nodeNumber = leaf.nodeNumber(root);
							String parentValue = leaf.parent(root).value();
							if (parentValue.equals("-NONE-")) {
								continue;
							}

							String word = Corpus.nodeToString(leaf).trim();

							if (fileName.equals("wsj_0998") && index == 4644) {
								continue;
							}

							if (word.equals(".") && !fileName.startsWith("wsj_23")) {
								continue;
							}

							// skipping dots after U.S. present in the parse
							// trees but not present in the original
							// text
							if (word.equals(".")) {
								if (fileName.equals("wsj_2303") && index == 1526) {
									continue;
								}

								if (fileName.equals("wsj_2314") && (index == 7625 || index == 7929)) {
									continue;
								}

								if (fileName.equals("wsj_2320") && (index == 474 || index == 3180)) {
									continue;
								}

								if (fileName.equals("wsj_2321") && index == 268) {
									continue;
								}

								if (fileName.equals("wsj_2324") && index == 490) {
									continue;
								}

								if (fileName.equals("wsj_2361") && index == 6563) {
									continue;
								}

								if (fileName.equals("wsj_2397") && (index == 2845 || index == 3273 || index == 3515)) {
									continue;
								}

								if (fileName.equals("wsj_2398") && index == 2793) {
									continue;
								}
							}

							word = word.replaceAll("`", "'");
							word = word.replaceAll("\\.\\.\\.", ". . .");

							if (fileName.equals("wsj_0004") && word.equals("IBC")) {
								word = "IBC/Donoghue";
							}
							if (fileName.equals("wsj_0032") && word.equals("S.p.A.")) {
								word = "S.p.\nA.";
							}
							if (fileName.equals("wsj_0986") && index == 1804) {
								word = "5/ 16";
							}
							if (fileName.equals("wsj_1737") && index == 689 && word.equals("U.S.")) {
								word = "U. S.";
							}
							if (fileName.equals("wsj_1974") && index == 1802 && word.equals("5/16")) {
								word = "5/ 16";
							}

							int span = orgText.indexOf(word, index);
							if (fileName.equals("wsj_0110") && word.equals("7/16")) {
								word = "7/ 16";
							}
							if (fileName.equals("wsj_0111") && word.equals("Rey/Fawcett")) {
								word = "Rey/ Fawcett";
							}
							if (fileName.equals("wsj_0162") && word.equals("International")) {
								word = "In< ternational";
							}
							if (fileName.equals("wsj_0359") && word.equals("Stovall/Twenty-First")) {
								word = "Stovall/ Twenty-First";
							}
							if (fileName.equals("wsj_0400") && word.equals("16/32")) {
								word = "16/ 32";
							}
							if (fileName.equals("wsj_0463") && word.equals("G.m.b.H.")) {
								word = "G.m.b.\nH.";
							}
							if (fileName.matches("wsj_(0660|1368|1371)")
									&& word.matches("S\\.p\\.A\\.?(-controlled)?")) {
								word = word.replaceAll("S\\.p\\.A", "S.p.\nA");
							}
							if (fileName.equals("wsj_0911") && word.equals("mystery/comedy")) {
								word = "mystery/ comedy";
							}
							if (fileName.matches("wsj_(0917|1329)") && word.equals("G.m.b.H.")) {
								word = "G.m.b.\nH.";
							}
							if (fileName.equals("wsj_0998") && word.equals("Co.")) {
								word = "Co,.";
							}
							if (fileName.equals("wsj_1237") && word.equals("Bard/EMS")) {
								word = "Bard/ EMS";
							}
							if (fileName.equals("wsj_1457")) {
								if (word.equals("fancy'shvartzer")) {
									word = "fancy 'shvartzer";
								} else if (word.equals("the'breakup")) {
									word = "the 'breakup";
								}
							}
							if (fileName.equals("wsj_1503") && word.equals("Gaming")) {
								word = "gaming";
							}
							if (fileName.equals("wsj_1568") && word.equals(". . .")) {
								word = "...";
							}
							if (fileName.equals("wsj_1583") && word.equals("'T-")) {
								word = "'T";
							}
							if (fileName.equals("wsj_1625") && word.equals("staff")) {
								word = "staf";
							}
							if (fileName.equals("wsj_1773") && word.equals("H.F.")) {
								word = "H. F.";
							}

							span = orgText.indexOf(word, index);

							if (fileName.equals("wsj_2170") && index == 7227 && word.equals("'s")) {
								span = 7227;
								word = "";
							}

							if (span == -1) {
								continue;
							}

							if (span - index > 1) {
								String difference = orgText.substring(index, span).trim();
								boolean isError = true;
								isError &= !(fileName.equals("wsj_0118") && difference.equals(".START"));
								isError &= !(fileName.matches("wsj_(0166|1156|2346)")
										&& difference.equals(". \n\n.START"));
								isError &= !(fileName.equals("wsj_0203") && index == 2835 && span == 2955);
								isError &= !difference.matches("\\p{Punct}") && difference.length() > 0;
								isError &= !difference.equals("�") && !difference.equals("><")
										&& !difference.equals(". \n\n>");
								isError &= !(fileName.equals("wsj_1625") && difference.equals("f"));
								isError &= !(fileName.equals("wsj_1839") && difference.equals(". ."));
								isError &= !(fileName.equals("wsj_2170") && difference.equals("'s"));
								isError &= !(fileName.equals("wsj_2346") && difference.equals(".START"));

							}
							index = span + word.length();

							String spanString = (span + ".." + (span + word.length()));
							String key = fileName + "," + treeNumber + "," + nodeNumber;
							word = word.trim().replaceAll("\\s+", "");
							word = word.replaceAll(",", "COMMA");
							pw.println(key + "," + spanString + "," + word);
						}
						root = tr.readTree();
						pw.flush();
						++treeNumber;
					}
					pw.close();
					tr.close();
				}
			}
		}
		log.info("Done.");
	}
}
