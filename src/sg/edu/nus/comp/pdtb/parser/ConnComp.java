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

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.model.Node;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Settings;
import edu.stanford.nlp.trees.Tree;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class ConnComp extends Component {

  public static final String NAME = "conn";

  public static final String[] PUNC_TAGS = {"#", "$", "``", "''", "-LRB-", "-RRB-", ",", ".", ":"};

  public static final String[] CONN_GROUP = {"on the other hand", "as a result",
      "as an alternative", "as long as", "as soon as", "before and after", "if and when",
      "in other words", "in the end", "on the contrary", "when and if", "as if", "as though",
      "as well", "by comparison", "by contrast", "by then", "for example", "for instance",
      "in addition", "in contrast", "in fact", "in particular", "in short", "in sum", "in turn",
      "insofar as", "much as", "now that", "so that", "accordingly", "additionally", "after",
      "afterward", "also", "alternatively", "although", "and", "as", "because", "before",
      "besides", "but", "consequently", "conversely", "earlier", "else", "except", "finally",
      "for", "further", "furthermore", "hence", "however", "if", "indeed", "instead", "later",
      "lest", "likewise", "meantime", "meanwhile", "moreover", "nevertheless", "next",
      "nonetheless", "nor", "once", "or", "otherwise", "overall", "plus", "previously", "rather",
      "regardless", "separately", "similarly", "simultaneously", "since", "so", "specifically",
      "still", "then", "thereafter", "thereby", "therefore", "though", "thus", "till",
      "ultimately", "unless", "until", "when", "whereas", "while", "yet"};
  public static final String[] CONN_INTRA = {"either..or", "if..then", "neither..nor"};

  public static final String[] Subordinator = {"after", "although", "as", "as if", "as long as",
      "as soon as", "as though", "because", "before", "before and after", "for", "however", "if",
      "if and when", "insofar as", "lest", "much as", "now that", "once", "since", "so", "so that",
      "though", "till", "unless", "until", "when", "when and if", "while"};

  public static final String[] Coordinator = {"and", "but", "else", "if..then", "neither..nor",
      "nor", "on the one hand..on the other hand", "or", "plus", "then", "yet"};

  public static final String[] Adverbial = {"accordingly", "additionally", "afterward", "also",
      "alternatively", "as a result", "as an alternative", "as well", "besides", "by comparison",
      "by contrast", "by then", "consequently", "conversely", "earlier", "either..or", "except",
      "finally", "for example", "for instance", "further", "furthermore", "hence", "in addition",
      "in contrast", "in fact", "in other words", "in particular", "in short", "in sum",
      "in the end", "in turn", "indeed", "instead", "later", "likewise", "meantime", "meanwhile",
      "moreover", "nevertheless", "next", "nonetheless", "on the contrary", "on the other hand",
      "otherwise", "overall", "previously", "rather", "regardless", "separately", "similarly",
      "simultaneously", "specifically", "still", "thereafter", "thereby", "therefore", "thus",
      "ultimately", "whereas"};

  public ConnComp() {
    super(NAME, ConnComp.class.getName());
    this.gsFile = new File(OUT_PATH + NAME + ".gs");

  }

  @Override
  public File train() throws IOException {

    File trainFile = new File(OUT_PATH + NAME + FeatureType.Training);
    PrintWriter featureFile = new PrintWriter(trainFile);
    PrintWriter spansFile = new PrintWriter(OUT_PATH + NAME + ".spans" + FeatureType.Training);

    log.info("Training:");
    for (int section : Settings.TRAIN_SECTIONS) {
      log.info("Section: " + section);
      File[] files = Corpus.getSectionFiles(section);

      for (File file : files) {
        log.trace("Article: " + file.getName());
        List<String[]> features = generateFeatures(file, FeatureType.GoldStandard);
        for (String[] feature : features) {
          featureFile.println(feature[0]);

          String[] tmp = feature[0].split("\\s+");
          String spanString =
              feature[1] + " " + feature[2] + " " + feature[3].replace(' ', '_') + " " + file + " "
                  + tmp[tmp.length - 1];

          spansFile.println(spanString);
        }
        featureFile.flush();
        spansFile.flush();
      }
    }
    featureFile.close();
    spansFile.close();

    File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);

    return modelFile;
  }

  @Override
  public File parseAnyText(File modelFile, File inputFile) throws IOException {
    String filePath = TMP_PATH + inputFile.getName() + "." + NAME;
    File testFile = new File(filePath);
    PrintWriter featureFile = new PrintWriter(testFile);
    PrintWriter spansFile = new PrintWriter(filePath + ".spans");

    List<String[]> features = generateFeatures(inputFile, FeatureType.AnyText);
    for (String[] feature : features) {
      featureFile.println(feature[0]);
      String[] tmp = feature[0].split("\\s+");
      String spanString =
          feature[1] + " " + feature[2] + " " + feature[3].replace(' ', '_') + " "
              + inputFile.getName() + " " + tmp[tmp.length - 1];
      spansFile.println(spanString);
    }
    featureFile.close();
    spansFile.close();

    File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(filePath + ".out"));

    return outFile;
  }

  @Override
  public File test(File modelFile, FeatureType featureType) throws IOException {

    String name = NAME + featureType.toString();
    File testFile = new File(OUT_PATH + name);
    PrintWriter featureFile = new PrintWriter(testFile);
    PrintWriter spansFile = new PrintWriter(OUT_PATH + name + ".spans");

    log.info("Printing " + featureType + " features: ");
    for (int section : Settings.TEST_SECTIONS) {
      log.info("Section: " + section);
      File[] files = Corpus.getSectionFiles(section);

      for (File file : files) {
        log.trace("Article: " + file.getName());
        List<String[]> features = generateFeatures(file, featureType);
        for (String[] feature : features) {
          featureFile.println(feature[0]);

          String[] tmp = feature[0].split("\\s+");
          String spanString =
              feature[1] + " " + feature[2] + " " + feature[3].replace(' ', '_') + " "
                  + file.getName() + " " + tmp[tmp.length - 1];

          spansFile.println(spanString);
        }
        featureFile.flush();
        spansFile.flush();
      }
    }
    featureFile.close();
    spansFile.close();

    File outFile =
        MaxEntClassifier.predict(testFile, modelFile, new File(Settings.OUT_PATH + name + ".out"));

    return outFile;
  }

  @Override
  public File test(FeatureType featureType) throws IOException {
    return test(modelFile, featureType);
  }

  @Override
  public List<String[]> generateFeatures(File article, FeatureType featureType) throws IOException {

    List<Tree> trees = Corpus.getTrees(article, featureType);
    Map<String, String> spanMap = Corpus.getSpanMap(article, featureType);

    Set<String> explicitSpans =
        featureType == FeatureType.AnyText ? null : Corpus.getExplicitSpansAsSet(article,
            featureType);

    List<String[]> features = new ArrayList<>();

    for (int i = 0; i < trees.size(); ++i) {
      Tree root = trees.get(i);
      if (root.children().length == 0) {
        continue;
      }
      List<Tree> leaves = root.getLeaves();

      Set<Integer> done = new HashSet<>();
      for (int j = 0; j < leaves.size(); ++j) {
        if (done.contains(j)) {
          continue;
        }

        String word = leaves.get(j).value().trim().toLowerCase();
        for (String conns : CONN_INTRA) {
          String[] conn = conns.split("\\.\\.");
          if (word.equals(conn[0])) {
            for (int k = j + 1; k < leaves.size(); ++k) {
              String other = leaves.get(k).value().trim().toLowerCase();
              if (!done.contains(k) && other.equals(conn[1])) {

                List<Node> nodes = new ArrayList<>();

                nodes.add(new Node(leaves.get(j), j));
                nodes.add(new Node(leaves.get(k), k));
                StringBuilder orgWord = new StringBuilder();
                orgWord.append(leaves.get(j).value().trim() + " ");
                orgWord.append(leaves.get(k).value().trim());

                done.add(j);
                if (!(article.getName().equals("wsj_2369.pipe") && j == 4 && k == 29 && i == 24)) {
                  done.add(k);
                }

                String key0 = i + ":" + nodes.get(0).tree.nodeNumber(root);
                String key1 = i + ":" + nodes.get(1).tree.nodeNumber(root);
                boolean isExplicit = false;

                String span0 = spanMap.get(key0);
                String span1 = spanMap.get(key1);
                if (explicitSpans != null) {
                  isExplicit = explicitSpans.contains(span0) && explicitSpans.contains(span1);
                }
                String span = span0 + ";" + span1;

                String feature = printFeature(root, nodes, isExplicit, true);

                features.add(new String[] {feature, span, i + "", orgWord.toString()});
              }
            }
          }
        }

        if (done.contains(j)) {
          continue;
        }

        for (String conns : CONN_GROUP) {
          String[] conn = conns.split("\\s+");
          if (word.equals(conn[0])) {
            boolean completeMatch = true;
            for (int k = 1; completeMatch && k < conn.length; ++k) {
              if (j + k == leaves.size()) {
                completeMatch = false;
                break;
              }
              String next = leaves.get(j + k).value().trim().toLowerCase();
              completeMatch &= !done.contains(k + j) && next.equals(conn[k]);
            }
            if (!done.contains(j) && completeMatch) {
              // if ( completeMatch) {
              List<Node> nodes = new ArrayList<>();
              StringBuilder orgWord = new StringBuilder();
              for (int k = 0; k < conn.length && j + k < leaves.size(); ++k) {
                nodes.add(new Node(leaves.get(j + k), j + k));
                orgWord.append(leaves.get(j + k).value().trim() + " ");
                done.add(j + k);
              }

              String key = i + ":" + nodes.get(0).tree.nodeNumber(root);
              String span = spanMap.get(key);
              if (nodes.size() > 1) {
                key = i + ":" + nodes.get(nodes.size() - 1).tree.nodeNumber(root);
                String spanEnd = spanMap.get(key);
                span = span.split("\\.\\.")[0] + ".." + spanEnd.split("\\.\\.")[1];
              }

              boolean isExplicit = false;
              if (explicitSpans != null) {
                isExplicit = explicitSpans.contains(span);
              }
              String feature = printFeature(root, nodes, isExplicit);
              features.add(new String[] {feature, span, i + "", orgWord.toString().trim()});
            }
          }
        }
      }
    }

    return features;
  }

  public static String printFeature(Tree root, List<Node> nodes, boolean isExplicit) {
    return printFeature(root, nodes, isExplicit, false);
  }

  public static String printFeature(Tree root, List<Node> nodes, boolean isExplicit, boolean isIntra) {
    char label = isExplicit ? '1' : '0';
    StringBuilder feature = new StringBuilder();

    StringBuilder tmp = new StringBuilder();
    StringBuilder tmp2 = new StringBuilder();
    for (Node node : nodes) {

      tmp.append(node.tree.parent(root).value() + " ");
      tmp2.append(node.tree.value() + " ");
    }
    String POS = tmp.toString().trim().replace(' ', '_');
    String connStr = tmp2.toString().trim().replace(' ', '_');
    if (isIntra) {
      connStr = connStr.replaceAll("_", "..");
    }
    List<Tree> leaves = root.getLeaves();

    int firstNodeNum = nodes.get(0).index;
    int lastNodeNum = nodes.get(nodes.size() - 1).index;

    Tree prevNode = firstNodeNum > 0 ? leaves.get(--firstNodeNum) : null;

    Tree nextNode = (leaves.size() > lastNodeNum + 1) ? leaves.get(++lastNodeNum) : null;

    feature.append("conn_lc:");
    feature.append(connStr.toLowerCase());
    feature.append(' ');

    feature.append("conn:");
    feature.append(connStr);
    feature.append(' ');

    feature.append("lexsyn:conn_POS:");
    feature.append(POS);
    feature.append(' ');

    if (prevNode != null) {
      while (prevNode.parent(root).value().equals("-NONE-") && firstNodeNum > 0) {
        prevNode = leaves.get(--firstNodeNum);
      }

      if (prevNode != null) {
        String prevPOS = prevNode.parent(root).value().replace(' ', '_');

        feature.append("lexsyn:with_prev_full:");
        feature.append(prevNode.value().replace(' ', '_'));
        feature.append('_');
        feature.append(connStr);
        feature.append(' ');

        feature.append("lexsyn:prev_POS:");
        feature.append(prevPOS);
        feature.append(' ');

        feature.append("lexsyn:with_prev_POS:");
        feature.append(prevPOS);
        feature.append('_');
        feature.append(POS.split("_")[0]);
        feature.append(' ');

        feature.append("lexsyn:with_prev_POS_full:");
        feature.append(prevPOS);
        feature.append('_');
        feature.append(POS);
        feature.append(' ');
      }
    }

    if (nextNode != null) {

      while (nextNode.parent(root).value().equals("-NONE-")) {
        nextNode = leaves.get(++lastNodeNum);
      }

      String nextPOS = nextNode.parent(root).value().replace(' ', '_');

      feature.append("lexsyn:with_next_full:");
      feature.append(connStr);
      feature.append('_');
      feature.append(nextNode.value().replace(' ', '_'));
      feature.append(' ');

      feature.append("lexsyn:next_POS:");
      feature.append(nextPOS);
      feature.append(' ');

      feature.append("lexsyn:with_next_POS:");
      feature.append(POS.split("_")[nodes.size() - 1]);
      feature.append('_');
      feature.append(nextPOS);
      feature.append(' ');

      feature.append("lexsyn:with_next_POS_full:");
      feature.append(POS);
      feature.append('_');
      feature.append(nextPOS);
      feature.append(' ');
    }

    // Pitler & Nenkova (ACL 09) features:
    Tree parent = getMutualParent(nodes, root);
    Tree grandparent = parent.parent(root);
    List<Tree> siblings = grandparent.getChildrenAsList();

    String selfCat = parent.value().split("-")[0].split("=")[0];
    String parentCat =
        grandparent.value() == null ? "NONE" : grandparent.value().split("-")[0].split("=")[0];

    Tree leftSib = null;
    Tree rightSib = null;
    String leftCat = "NONE";
    String rightCat = "NONE";

    int index = siblings.indexOf(parent);

    if (index > 0) {
      leftSib = siblings.get(index - 1);
      leftCat =
          leftSib.value().startsWith("-") ? leftSib.value() : leftSib.value().split("-")[0]
              .split("=")[0];
      leftCat = leftCat.isEmpty() ? "-NONE-" : leftCat;
    }

    if (index < siblings.size() - 1) {
      rightSib = siblings.get(index + 1);
      rightCat =
          rightSib.value().startsWith("-") ? rightSib.value() : rightSib.value().split("-")[0]
              .split("=")[0];
      rightCat = rightCat.isEmpty() ? "-NONE-" : rightCat;
    }

    boolean rightVP = containsNode(rightSib, "VP");
    boolean rightTrace = containsTrace(rightSib);

    List<String> syn = new ArrayList<>();
    syn.add("selfCat:" + selfCat);
    syn.add("parentCat:" + parentCat);
    syn.add("leftCat:" + leftCat);
    syn.add("rightCat:" + rightCat);

    if (rightVP) {
      syn.add("rightVP");
    }
    if (rightTrace) {
      syn.add("rightTrace");
    }

    for (String cat : syn) {
      feature.append("syn:");
      feature.append(cat);
      feature.append(' ');
    }

    for (String cat : syn) {
      feature.append("conn-syn:conn:");
      feature.append(connStr);
      feature.append('-');
      feature.append(cat);
      feature.append(' ');
    }

    for (int i = 0; i < syn.size(); ++i) {
      for (int j = i + 1; j < syn.size(); ++j) {
        feature.append("syn-syn:");
        feature.append(syn.get(i));
        feature.append('-');
        feature.append(syn.get(j));
        feature.append(' ');
      }
    }

    String[] synFeatures = getSyntacticfeatures(parent, root);

    feature.append("path-self>root:");
    feature.append(synFeatures[0]);
    feature.append(' ');

    feature.append("path-self>root2:");
    feature.append(synFeatures[1]);
    feature.append(' ');

    feature.append(label);

    return feature.toString().replaceAll("/", "\\\\/");
  }

  private static String[] getSyntacticfeatures(Tree node, Tree root) {
    StringBuilder selfToRoot = new StringBuilder();
    StringBuilder selfToRootNoRepeat = new StringBuilder();
    String val = node.value().split("-")[0].split("=")[0];
    selfToRoot.append(val);
    selfToRootNoRepeat.append(node.value().split("-")[0].split("=")[0]);

    Tree prev = node;
    node = node.parent(root);

    while (!node.equals(root)) {

      selfToRoot.append("_>_");
      selfToRoot.append(node.value().split("-")[0].split("=")[0]);
      if (!prev.value().split("-")[0].equals(node.value().split("-")[0].split("=")[0])) {
        selfToRootNoRepeat.append("_>_");
        selfToRootNoRepeat.append(node.value().split("-")[0].split("=")[0]);
      }
      prev = node;
      node = node.parent(root);

    }
    return new String[] {selfToRoot.toString(), selfToRootNoRepeat.toString()};
  }

  public static Tree getMutualParent(List<Node> nodes, Tree root) {
    int maxNodeNum = 0;

    for (Node node : nodes) {
      maxNodeNum = Math.max(maxNodeNum, node.tree.nodeNumber(root));
    }
    int nodeNum = 0;
    Tree parent = nodes.get(0).tree;

    while (nodeNum < maxNodeNum && !parent.equals(root)) {
      parent = parent.parent(root);
      List<Tree> children = parent.getLeaves();
      Tree rightMostChild = children.get(children.size() - 1);
      nodeNum = rightMostChild.nodeNumber(root);
    }

    return parent;
  }

  private static boolean containsTrace(Tree node) {
    if (node == null) {
      return false;
    }
    if (node.value().equals("-NONE-") && node.firstChild().value().matches("^\\*T\\*.*")) {
      return true;
    }
    List<Tree> children = node.getChildrenAsList();
    for (Tree child : children) {
      if (containsTrace(child)) {
        return true;
      }
    }

    return false;
  }

  private static boolean containsNode(Tree node, String nodeValue) {
    if (node == null) {
      return false;
    }
    String value = node.value();
    value = value.split("=").length > 1 ? value.split("=")[0] : value;
    value = value.split("-").length > 1 ? value.split("-")[0] : value;

    if (value.equals(nodeValue)) {
      return true;
    }
    List<Tree> children = node.getChildrenAsList();
    for (Tree child : children) {
      if (containsNode(child, nodeValue)) {
        return true;
      }
    }

    return false;
  }

  public static String findCategory(String connStr) {
    if (connStr == null) {
      return null;
    }

    String key = connStr.toLowerCase();
    if (key.equals("either or")) {
      key = "either..or";
    }

    String value = "Subordinator";

    for (String can : Subordinator) {
      if (key.equals(can)) {
        return value;
      }
    }

    value = "Conj-adverb";
    for (String can : Adverbial) {
      if (key.equals(can)) {
        return value;
      }
    }

    value = "Coordinator";
    key = key.replaceAll("\\s+", "..");
    for (String can : Coordinator) {
      if (key.equals(can)) {
        return value;
      }
    }

    return null;
  }

}
