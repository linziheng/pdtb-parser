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

package sg.edu.nus.comp.pdtb.util;

import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkIsNumber;
import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkTrueOrThrowError;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

import sg.edu.nus.comp.pdtb.model.Relation;
import sg.edu.nus.comp.pdtb.model.TextSpan;
import sg.edu.nus.comp.pdtb.model.Type;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 */
public class Util {

	public static final String NEW_LINE = System.getProperty("line.separator");
	public static final String ENCODING = "UTF-8";

	private static final Pattern PUNCTUATION = Pattern.compile("[\\:\\;\\-\\_\\!\\?`'`',\\.]",
			Pattern.CASE_INSENSITIVE);

	private static final FilenameFilter filter = new FilenameFilter() {
		@Override
		public boolean accept(File dir, String name) {
			return name.endsWith(".pipe");
		}
	};

	// It's a static class so hide the default constructor.
	private Util() {
	}

	/**
	 * Check if two arrays have at least one common element.
	 * 
	 * @param array1
	 *            first object array
	 * @param array2
	 *            second object array
	 * @return Returns {@code true} if the arrays have one or more common
	 *         elements
	 */
	public static boolean arraysIntersect(Object[] array1, Object[] array2) {

		boolean intersect = false;
		for (int i = 0; i < array1.length && !intersect; ++i) {

			Object e1 = array1[i];
			if (e1 != null) {
				for (int j = 0; j < array2.length && !intersect; ++j) {
					Object e2 = array2[j];
					intersect = e1.equals(e2);
				}
			}
		}

		return intersect;
	}

	/**
	 * Check if array contains only {@code null} elements.
	 * 
	 * @param array
	 *            an object array
	 * @return Returns {@code true} if the array has <b>only</b> {@code null}
	 *         elements.
	 */
	public static boolean isEmpty(Object[] array) {
		boolean isEmpty = true;

		for (int i = 0; i < array.length && isEmpty; i++) {
			if (array[i] != null) {
				isEmpty = false;
			}
		}

		return isEmpty;
	}

	/**
	 * Prints the message:
	 * 
	 * <pre>
	 * "{@code in}"is invalid semantic level, only 1, 2 or 3 are allowed.
	 * 
	 * </pre>
	 * 
	 * @param out
	 *            the {@code PrintStream} to print the message to
	 * @param in
	 *            the invalid level string
	 */
	public static void printInvalidLevel(PrintStream out, String in) {
		out.println("\"" + in + "\" is invalid semantic level, only 1, 2 or 3 are allowed.");
	}

	/**
	 * Prints the message:
	 * 
	 * <pre>
	 * Usage: java -jar scorer.jar predictedFileName expectedFileName semanticLevel [errorFileName outputFileName]
	 *      predictedFileName - path to the file being scored
	 *      expectedFileName - path to the file containing the gold standard annotations
	 *      semanticLevel - semantic type level used to evaluate the annotations (1, 2 or 3)
	 * Optional:
	 *      errorFileName - path to a file to print error messages to. The default value is "errors_[timestamp].txt"
	 *      outputFileName - path to a file to print results  to. The default value is to print to console.
	 * </pre>
	 * 
	 * @param out
	 *            the {@code PrintStream} to print the message to
	 */
	public static void printHelpMessage(PrintStream out) {

		out.print("Usage: java -jar scorer.jar predictedFileName expectedFileName");
		out.println(" semanticLevel [errorFileName outputFileName]");

		out.println("\t predictedFileName - path to the file being scored");

		out.print("\t expectedFileName - ");
		out.println("path to the file containing the gold standard annotations");

		out.print("\t semanticLevel - ");
		out.println("semantic type level used to evaluate the annotations (1, 2 or 3)");

		out.println("Optional:");

		out.print("\t errorFileName - ");
		out.print("path to a file to print error messages to.");
		out.println(" The default value is \"errors_[timestamp].txt\"");

		out.print("\t outputFileName - ");
		out.print("path to a file to print results to.");
		out.println(" The default value is to print to console.");
	}

	public static int[][] getSpanListRange(String spanList) {

		String[] spans = spanList.split(";");
		int[][] spanListRange = new int[spans.length][2];

		for (int i = 0; i < spans.length; ++i) {
			String span = spans[i];
			String[] range = span.split("\\.{2}");

			checkIsNumber(range[0], "SpanList");
			spanListRange[i][0] = Integer.parseInt(range[0]);

			checkIsNumber(range[1], "SpanList");
			spanListRange[i][1] = Integer.parseInt(range[1]);
		}

		return spanListRange;
	}

	public static int[][] getGornAddresses(String gornAddressList) {

		String[] addresses = gornAddressList.split(";");
		int[][] gornAddresses = new int[addresses.length][];

		for (int i = 0; i < addresses.length; ++i) {
			String[] address = addresses[i].split(",");
			gornAddresses[i] = new int[address.length];
			for (int j = 0; j < address.length; ++j) {
				checkIsNumber(address[j], "GornAddress");
				gornAddresses[i][j] = Integer.parseInt(address[j]);
			}
		}

		return gornAddresses;
	}

	/**
	 * It reads all .pipe files in the directory.
	 * 
	 * @param directory
	 * @return
	 * @throws IOException
	 */
	public static Map<Long, List<Relation>> readRelations(File directory) throws IOException {

		checkTrueOrThrowError(directory.isDirectory(), directory.getName() + " is not a directory.");
		File[] files = directory.listFiles(filter);
		Map<Long, List<Relation>> relations = new HashMap<>();

		for (File file : files) {
			try (BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(file), "UTF8"))) {

				String pipeLine;
				while ((pipeLine = reader.readLine()) != null) {

					Relation aRelation = new Relation(pipeLine);
					List<Relation> list = relations.get(aRelation.getKey());
					if (list == null) {
						list = new ArrayList<>();
					}
					list.add(aRelation);
					relations.put(aRelation.getKey(), list);
				}

			}
		}

		return relations;
	}

	/**
	 * It returns the offset indices to remove leading and trailing punctuation
	 * symbols. To get the trimmed string call
	 * {@code text.substring(offset[0], text.length() - offset[1])}.
	 * <p>
	 * It does <b>not</b> consider whitespace characters, so the text should be
	 * whitespace trimmed ( {@code text.trim()}) before calling this method.
	 * 
	 * <p>
	 * Punctuation symbols considered:
	 * 
	 * <pre>
	 * : ; - _ ! ? ` ' ` ' , .
	 * </pre>
	 * 
	 * @param text
	 *            a string to get offset indices for
	 * @return an int array with two elements, the offset for the start and the
	 *         end of the string {@code text}, {@code [start,end]}
	 */
	public static int[] getPunctuationOffset(String text) {

		int meStartOffset = 0;
		int meEndOffset = 0;

		for (int i = 0; i < text.length() - 1; ++i) {
			CharSequence sequence = text.subSequence(i, i + 1);
			if (PUNCTUATION.matcher(sequence).matches()) {
				meStartOffset = i + 1;
			} else {
				break;
			}
		}

		for (int i = text.length(); i > 0; --i) {
			CharSequence sequence = text.subSequence(i - 1, i);
			if (PUNCTUATION.matcher(sequence).matches()) {
				meEndOffset = text.length() - i + 1;
			} else {
				break;
			}
		}

		return new int[] { meStartOffset, meEndOffset };
	}

	public static int[] offsetRange(int[][] range, int[] offset) {

		int start = range[0][0] + offset[0];
		int end = range[range.length - 1][1] - offset[1];

		return new int[] { start, end };
	}

	public static int getSizeForType(Type type, Map<Integer, List<Relation>> map) {

		int size = 0;

		for (List<Relation> relations : map.values()) {
			for (Relation relation : relations) {
				if (type == relation.getType()) {
					++size;
				}
			}
		}

		return size;
	}

	public static Integer[] getPositionForSpan(int[][] spanListRange, int[] posNumbers) throws IOException {
		Set<Integer> clauseNumbers = new TreeSet<>();

		for (int i = 0; i < spanListRange.length; ++i) {
			for (int j = 0; j < spanListRange[i].length; ++j) {
				int span = spanListRange[i][j];
				int clauseNumber = Arrays.binarySearch(posNumbers, span);
				if (clauseNumber < 0) {
					clauseNumber = -(clauseNumber + 1) - 1;
				}
				clauseNumbers.add(clauseNumber);
			}
		}

		return clauseNumbers.toArray(new Integer[clauseNumbers.size()]);
	}

	public static int[][] getPositionNumbersForArticle(int section, int fileNumber) throws IOException {
		String sec = String.format("%02d", section);
		String fi = String.format("%02d", fileNumber);
		File file = new File("test_resources/PDTB/clause_numbers/" + sec + "/txt_" + sec + fi);

		BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(file), ENCODING));

		int[][] result = new int[3][];

		for (int j = 0; j < result.length; ++j) {
			String[] numbers = reader.readLine().split(",");
			result[j] = new int[numbers.length];
			for (int i = 0; i < numbers.length; ++i) {
				result[j][i] = Integer.parseInt(numbers[i]);
			}
		}

		reader.close();
		return result;
	}

	/**
	 * <pre>
	 * First line clause numbers.
	 * Second line sentence numbers.
	 * Third line paragraph numbers.
	 * </pre>
	 * 
	 * @throws IOException
	 */
	public static void generateClauseNumbers() throws IOException {

		String rawTextDir = "test_resources/PDTB/raw_text/";
		String output = "test_resources/PDTB/clause_numbers/";
		for (int i = 0; i < 25; ++i) {
			String dir = output + String.format("%02d", i) + "/";
			(new File(dir)).mkdir();
			String section = rawTextDir + String.format("%02d", i);
			File[] files = new File(section).listFiles();
			for (File file : files) {
				String fileName = file.getName().split("_")[1];
				PrintWriter pw = new PrintWriter(new File(dir + "txt_" + fileName));
				String text = readFile(file);
				String[] lines = text.split("\\n+|(\\D:)|;");

				if (fileName.equals("1554")) {
					// System.out.println("D");
				}
				StringBuilder sb = new StringBuilder();
				int prevIndex = 0;
				for (int j = 0; j < lines.length; ++j) {
					int ind = text.indexOf(lines[j].trim(), prevIndex);
					if (ind < 0) {
						System.out.println("D");
					}
					sb.append(ind + ",");
					prevIndex = ind;
				}
				sb.append(text.length());
				pw.println(sb);
				lines = text.split("\\n+");
				sb = new StringBuilder();
				prevIndex = 0;
				for (int j = 0; j < lines.length; ++j) {
					int ind = text.indexOf(lines[j].trim(), prevIndex);
					if (ind < 0) {
						System.out.println("D");
					}
					sb.append(ind + ",");
					prevIndex = ind;
				}
				sb.append(text.length());
				pw.println(sb);
				lines = text.split("\\n");
				sb = new StringBuilder("0,");
				prevIndex = 0;
				for (int j = 0; j < lines.length; ++j) {
					if (lines[j].isEmpty()) {
						int ind = text.indexOf(lines[j + 1].trim(), prevIndex);
						if (ind < 0) {
							System.out.println("D");
						}
						sb.append(ind + ",");
						prevIndex = ind;
					}
				}
				sb.append(text.length());
				pw.println(sb);
				pw.print(text);
				pw.close();
			}
		}
	}

	public static String readFile(String fileName) throws IOException {
		return readFile(fileName, ENCODING);
	}

	public static String readFile(File file) throws IOException {
		return readFile(file, ENCODING);
	}

	public static String readFile(String fileName, String encoding) throws IOException {
		return readFile(new File(fileName), encoding);
	}

	public static String readFile(File file, String encoding) throws IOException {
		StringBuilder sb = new StringBuilder();

		try (BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(file), encoding))) {
			char[] tmp = new char[256];
			int r = reader.read(tmp);
			while (r != -1) {
				sb.append(tmp, 0, r);
				r = reader.read(tmp);
			}
		}

		return sb.toString();
	}

	public static Map<Long, List<Relation>> readWholeDataset() throws IOException {
		Map<Long, List<Relation>> rels = new HashMap<>();
		for (int i = 0; i < 25; ++i) {
			rels.putAll(readRelations(new File("test_resources/PDTB/expected/" + String.format("%02d", i))));
		}

		return rels;
	}

	/**
	 * Count how many unique relations there are in the map.
	 * 
	 * @param map
	 *            containing lists of relations
	 * @return total number of relations in all lists
	 */
	public static int countRelations(Map<Long, List<Relation>> map) {
		int count = 0;
		for (List<Relation> relations : map.values()) {
			count += relations.size();
		}
		return count;
	}

	public static void main(String[] args) throws IOException {
		genStat();
		// stat1();
		// Map<Long, List<Relation>> map = filterByType(Type.EXPLICIT,
		// readWholeDataset());
		// int[] c = new int[6];
		// for (List<Relation> rels : map.values()) {
		// for (Relation rel : rels) {
		// int l = rel.getConnective().getSpanListRange().length;
		// ++c[l];
		// if(l == 2){
		// System.out.println(rel);
		// }
		//
		// }
		// }
		// System.out.println(Arrays.toString(c));
		// genStat();
		// generateClauseNumbers();
	}

	@SuppressWarnings("unused")
	private static void genStat() throws IOException {
		Map<Long, List<Relation>> map = readWholeDataset();
		map = filterByType(Type.ENT_REL, map);
		int[] sCl = new int[50];
		int[] sSent = new int[50];
		int[] sPara = new int[50];
		int[] arg1Parts = new int[10];
		int[] arg2Parts = new int[10];

		int[][] start = new int[2][2];

		for (List<Relation> rels : map.values()) {
			for (Relation rel : rels) {
				int[][] posNumbers = getPositionNumbersForArticle(rel.getSection(), rel.getFileNumber());
				String text = readArticle(rel);
				if (!isSorted(posNumbers)) {
					System.out.println(isSorted(posNumbers));
				}
				// if (rel.getSection() == 5 && rel.getFileNumber() == 94) {
				// continue;
				// }
				int a1 = rel.getArg1().getSpanListRange().length;
				int a2 = rel.getArg2().getSpanListRange().length;
				++arg1Parts[a1];
				++arg2Parts[a2];

				TextSpan span = rel.getArg1();

				String extracted = getSpanText(text, span);

				// if (!extracted.equals(span.getRawText())) {
				// System.out.println(span.getRawText());
				// System.out.println(extracted);
				// }

				int[][] range = span.getSpanListRange();
				int swit = 1;
				String[] clauses = getSpans(text, posNumbers[swit]);
				for (int i = 0; i < range.length; ++i) {
					for (int j = 0; j < range[i].length; ++j) {
						int clauseNumber = Arrays.binarySearch(posNumbers[swit], range[i][j]);
						if (clauseNumber < 0) {
							clauseNumber = -(clauseNumber + 1) - 1;
						}
						int clauseStart = posNumbers[swit][clauseNumber + j];
						String difference;
						if (j == 0) {
							difference = text.substring(clauseStart, range[i][j]);
						} else {
							difference = text.substring(range[i][j], clauseStart);
						}
						difference = difference.trim().replaceAll("\\.|\\?|\\|!|\\s|\"", "");
						if (difference.isEmpty()) {
							++start[j][0];
						} else {
							++start[j][1];
						}
					}
				}
				Integer[] cl = getPositionForSpan(span, posNumbers[0]);
				Integer[] sent = getPositionForSpan(span, posNumbers[1]);
				Integer[] para = getPositionForSpan(span, posNumbers[2]);

				int c = cl.length == 1 ? 1 : cl[cl.length - 1] - cl[0] + 1;
				int s = sent.length == 1 ? 1 : sent[sent.length - 1] - sent[0] + 1;
				int p = para.length == 1 ? 1 : para[para.length - 1] - para[0] + 1;

				// if (a1 > 2) {
				// System.out.println(rel.getSentence() + " " + " " +
				// rel.getSection() + ","
				// + rel.getFileNumber());
				// System.out.println(span.getRawText());
				// }
				++sCl[c];
				if (s > 1) {
					System.out.println(rel);
				}
				++sSent[s];
				++sPara[p];
			}
		}
		System.out.println(Arrays.toString(start[0]));
		System.out.println(Arrays.toString(start[1]));
		//
		System.out.println(Arrays.toString(sCl));
		System.out.println(Arrays.toString(sSent));
		System.out.println(Arrays.toString(sPara));
		System.out.println();
		System.out.println(Arrays.toString(arg1Parts));
		System.out.println(Arrays.toString(arg2Parts));
	}

	private static String[] getSpans(String text, int[] num) {
		String[] result = new String[num.length];
		for (int i = 0; i < num.length - 1; ++i) {
			result[i] = text.substring(num[i], num[i + 1]);
		}
		return result;
	}

	private static String getSpanText(String text, TextSpan span) {
		StringBuilder sb = new StringBuilder();
		int[][] range = span.getSpanListRange();
		for (int i = 0; i < range.length; ++i) {
			String temp = text.substring(range[i][0], range[i][1]).replaceAll("\\n", "").trim();
			if (sb.length() > 0 && !(sb.charAt(sb.length() - 1) == '.' && Character.isUpperCase(temp.charAt(0)))) {
				sb.append(" ");
			}
			sb.append(temp);
		}
		return sb.toString().trim();
	}

	private static String readArticle(Relation rel) throws IOException {
		String sec = String.format("%02d", rel.getSection());
		String fi = String.format("%02d", rel.getFileNumber());
		File file = new File("test_resources/PDTB/raw_text/" + sec + "/wsj_" + sec + fi);

		return readFile(file);
	}

	private static boolean isSorted(int[][] posNumbers) {
		for (int i = 0; i < posNumbers.length; ++i) {
			int num = -1;
			for (int j = 0; j < posNumbers[i].length; ++j) {
				if (num > posNumbers[i][j]) {
					return false;
				}
				num = posNumbers[i][j];
			}
		}

		return true;
	}

	private static Integer[] getPositionForSpan(TextSpan span, int[] posNumbers) throws IOException {
		return getPositionForSpan(span.getSpanListRange(), posNumbers);
	}

	public static String getSemanticStatistics(Map<Long, List<Relation>> map) {

		int[] stat = new int[5];

		for (List<Relation> relations : map.values()) {
			for (Relation relation : relations) {
				Set<String> classes = relation.getSemanticClass().getUniqueClasses();
				int size = classes.size();
				++stat[size];
			}
		}

		return Arrays.toString(stat);
	}

	public static String getMapStatistics(Map<Long, List<Relation>> map) {
		StringBuilder sb = new StringBuilder();
		int count = 0;
		int[][] c = new int[5][5];

		for (List<Relation> relations : map.values()) {
			c[relations.size()][relations.get(0).getType().getId()]++;

			if (relations.size() == 2 && relations.get(0).getType().equals(Type.ENT_REL)) {
				for (Relation relation : relations) {
					sb.append(relation);
					sb.append(NEW_LINE);
				}
				sb.append("===");
				sb.append(NEW_LINE);
			}
			count += relations.size();
		}

		for (int i = 0; i < 5; ++i) {
			sb.append(Arrays.toString(c[i]));
			sb.append(NEW_LINE);
		}
		for (Type type : Relation.allTypes) {
			sb.append(type + " : " + type.getId());
			sb.append(NEW_LINE);
		}

		sb.append("Total relations: " + count);
		sb.append(NEW_LINE);
		sb.append("Unique keys: " + map.size());
		sb.append(NEW_LINE);

		return sb.toString();

	}

	public static Map<Long, List<Relation>> filterByType(Type targetType, Map<Long, List<Relation>> map) {

		Map<Long, List<Relation>> filteredMap = new HashMap<>();

		for (List<Relation> rels : map.values()) {
			long key = rels.get(0).getKey();
			Type aType = rels.get(0).getType();
			if (aType.equals(targetType)) {
				filteredMap.put(key, rels);
			}
		}

		return filteredMap;
	}

	public static String extractSemantic(String semantic, int level) {
		String result = null;

		String[] semClass = semantic.split("\\.");

		if (semClass.length >= level) {
			result = semClass[level - 1];
		}

		if (result == null) {
			return "";
		} else {
			return result.trim();
		}
	}

	/**
	 * Check if an <b>unsorted</b> array contains an element.
	 * <p>
	 * Complexity <i>O(n)</i>.
	 * 
	 * @param array
	 * @param element
	 * @return
	 */
	public static boolean arrayContains(Object[] array, Object element) {
		return arrayContains(array, element, false);
	}

	/**
	 * Check if any type of array contains an element.
	 * 
	 * <ul>
	 * Complexity:
	 * <li>for unsorted array: <i>O(n)</i>
	 * <li>for sorted array: <i>O(log(n))</i>
	 * 
	 * <p>
	 * 
	 * @param array
	 * @param element
	 * @param isSorted
	 * @return true if the array contains an element that returns {@code true}
	 *         for the {@code element} when calling {@code equals}
	 */
	public static boolean arrayContains(Object[] array, Object element, boolean isSorted) {

		if (isSorted) {
			return Arrays.binarySearch(array, element) >= 0;
		} else {
			for (int i = 0; i < array.length; ++i) {
				if (array[i].equals(element)) {
					return true;
				}
			}
			return false;
		}
	}

	public static boolean removeDir(String dirPath) {
		boolean result = true;
		File dir = new File(dirPath);
		File[] files = dir.listFiles();
		if (files != null) {
			for (File file : files) {
				result &= file.delete();
			}
			result &= dir.delete();
		}
		return result;
	}

	public static Set<String> getUniqueSense(String[] semSenses, int lvl) {
		Set<String> set = new HashSet<>();

		for (String st : semSenses) {
			String e = extractSemantic(st, lvl);
			if (e != null && e.length() > 0) {
				set.add(e);
			}
		}

		return set;
	}

	public static Set<String> getUniqueSense(String[] strings) {
		return getUniqueSense(strings, Settings.SEMANTIC_LEVEL);
	}

	public static BufferedReader reader(File spans) throws UnsupportedEncodingException, FileNotFoundException {
		return new BufferedReader(new InputStreamReader(new FileInputStream(spans), Util.ENCODING));
	}

	public static BufferedReader reader(String string) throws UnsupportedEncodingException, FileNotFoundException {
		return reader(new File(string));
	}

	public static int[] toIntArray(String value) {
		if (value == null) {
			return null;
		}
		String[] values = value.split(",");
		int[] intArray = new int[values.length];

		for (int i = 0; i < intArray.length; i++) {
			intArray[i] = Integer.valueOf(values[i]);
		}

		return intArray;
	}

	public static Map<String, Field> getStaticFields(Class<Settings> aClass) {
		Map<String, Field> classFields = new HashMap<>();
		Field[] fields = aClass.getFields();
		for (Field field : fields) {
			if (Modifier.isStatic(field.getModifiers())) {
				String key = field.getName();
				classFields.put(key, field);
			}
		}

		return classFields;
	}

}
