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
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import sg.edu.nus.comp.pdtb.parser.ArgExtComp;
import sg.edu.nus.comp.pdtb.parser.ArgPosComp;
import sg.edu.nus.comp.pdtb.parser.Component;
import sg.edu.nus.comp.pdtb.parser.ConnComp;
import sg.edu.nus.comp.pdtb.parser.ExplicitComp;
import sg.edu.nus.comp.pdtb.parser.NonExplicitComp;
import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;
import edu.stanford.nlp.ling.HasWord;
import edu.stanford.nlp.parser.lexparser.LexicalizedParser;
import edu.stanford.nlp.process.DocumentPreprocessor;
import edu.stanford.nlp.trees.Tree;
import edu.stanford.nlp.trees.TreePrint;

public class PdtbParser {
  private static Logger log = LogManager.getLogger(PdtbParser.class.toString());

  public static void main(String[] args) throws IOException {

    if (args.length < 1) {
      System.out.println("Please supply the path to a text file you want to parse. ");
    } else {
      String testFilePath = args[0];
      File inputFile = new File(testFilePath);
      parseFile(inputFile);
    }
  }

  private static void parseFile(File inputFile) throws IOException {
    prepareAuxData(inputFile);
    log.info("Running the PDTB parser");
    Component parser = new ConnComp();
    log.info("Running connective classifier...");
    parser.parseAnyText(inputFile);
    log.info("Done.");
    parser = new ArgPosComp();
    log.info("Running argument position classifier...");
    parser.parseAnyText(inputFile);
    log.info("Done.");
    parser = new ArgExtComp();
    log.info("Running argument extractor classifier...");
    File pipeFile = parser.parseAnyText(inputFile);
    Map<String, String> pipeMap = genPipeMap(pipeFile);
    log.info("Done.");
    parser = new ExplicitComp();
    log.info("Running Explicit classifier...");
    File expSenseFile = parser.parseAnyText(inputFile);
    joinSense(pipeMap, expSenseFile, pipeFile);
    log.info("Done.");
    parser = new NonExplicitComp();
    log.info("Running NonExplicit classifier...");
    File nonExpSenseFile = parser.parseAnyText(inputFile);
    appendToFile(pipeFile, nonExpSenseFile);
    log.info("Done with everything. The PDTB relations for the file are in: " + pipeFile);
  }

  private static void appendToFile(File pipeFile, File nonExpSenseFile) throws IOException {

    try (FileWriter writer = new FileWriter(pipeFile, true);
        BufferedReader reader = Util.reader(nonExpSenseFile)) {
      String line;
      while ((line = reader.readLine()) != null) {
        writer.write(line + Util.NEW_LINE);
      }
    }
  }

  private static void joinSense(Map<String, String> pipeMap, File expSenseFile, File pipeFile)
      throws IOException {
    try (BufferedReader reader = Util.reader(expSenseFile)) {
      String line;
      while ((line = reader.readLine()) != null) {
        String[] tmp = line.split("\\|", -1);
        String pipe = pipeMap.get(tmp[0]);
        if (pipe == null) {
          log.error("Cannot find connective span in pipe map.");
        }
        String[] cols = pipe.split("\\|", -1);

        StringBuilder resultLine = new StringBuilder();

        for (int i = 0; i < cols.length; i++) {
          String col = cols[i];
          if (i == 11) {
            resultLine.append(tmp[1] + "|");
          } else {
            resultLine.append(col + "|");
          }
        }
        resultLine.deleteCharAt(resultLine.length() - 1);
        cols = resultLine.toString().split("\\|", -1);

        pipeMap.put(tmp[0], resultLine.toString());
      }
    }

    PrintWriter pw = new PrintWriter(pipeFile);
    for (String pipe : pipeMap.values()) {
      pw.println(pipe);
    }
    pw.close();
  }

  private static Map<String, String> genPipeMap(File pipeFile) throws IOException {

    Map<String, String> map = new HashMap<>();
    try (BufferedReader reader = Util.reader(pipeFile)) {
      String line;

      while ((line = reader.readLine()) != null) {
        String[] cols = line.split("\\|", -1);
        map.put(cols[3], line);
      }
    }
    return map;
  }

  private static void prepareAuxData(File testFile) throws IOException {

    File[] trees = prepareParseAndDependecyTrees(testFile);

    SpanTreeExtractor.anyTextToSpanGen(trees[0], testFile);
  }

  private static File[] prepareParseAndDependecyTrees(File inputFile) throws FileNotFoundException {
    log.info("Generating parse and dependecy trees with Stanford parser...");
    String outDir = Settings.TMP_PATH + inputFile.getName();
    LexicalizedParser lp = LexicalizedParser.loadModel("external/lib/englishPCFG.ser.gz");
    File parseTree = new File(outDir + ".ptree");
    File dependTree = new File(outDir + ".dtree");
    PrintWriter parse = new PrintWriter(parseTree);
    TreePrint tp = new TreePrint("penn");
    PrintWriter depend = new PrintWriter(dependTree);
    TreePrint td = new TreePrint("typedDependencies");

    DocumentPreprocessor sentence = new DocumentPreprocessor(inputFile.toString());
    for (List<HasWord> sent : sentence) {
      Tree tree = lp.apply(sent);

      tp.printTree(tree, parse);
      parse.flush();

      td.printTree(tree, depend);
      depend.flush();
    }
    parse.close();
    depend.close();
    log.info("Tree generation done.");
    return new File[] {parseTree, dependTree};
  }

}
