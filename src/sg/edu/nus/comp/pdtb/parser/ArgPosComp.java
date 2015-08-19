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

/**
 * 
 */
package sg.edu.nus.comp.pdtb.parser;

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
import edu.stanford.nlp.trees.Tree;

/**
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class ArgPosComp extends Component {

  public static final String NAME = "argpos";

  public ArgPosComp() {
    super(NAME, ArgPosComp.class.getName());
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
      Set<Integer> done = new HashSet<>();
      String label =
          (featureType == FeatureType.AnyText) ? "NA" : Corpus.getLabel(cols[23], cols[33]);
      
      label = label.endsWith("PS") ? "PS" : label;
      if (label.equals("FS")) {
        continue;
      }
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
          if (span[0].equals(canSpan[0])
              || (nodes.size() > 0 && spans.length == 1 && Integer.parseInt(canSpan[1]) <= Integer
                  .parseInt(span[1]))) {
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

            if (!done.contains(nodeNum) && cols[5].contains(node.value().trim())) {
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
        String feature = printFeature(root, nodes, label);
        features.add(new String[] {feature, rel});
      }
    }

    return features;
  }

  private String printFeature(Tree root, List<Node> nodes, String label) {
    StringBuilder tmp = new StringBuilder();
    StringBuilder tmp2 = new StringBuilder();
    for (Node node : nodes) {
      tmp.append(node.tree.parent(root).value() + " ");
      tmp2.append(node.tree.value() + " ");
    }
    String POS = tmp.toString().trim().replace(' ', '_');
    String connStr = tmp2.toString().trim().replace(' ', '_');

    if (connStr.equalsIgnoreCase("if_then") || connStr.equalsIgnoreCase("either_or")
        || connStr.equalsIgnoreCase("neither_nor")) {
      connStr = connStr.replaceAll("_", "..");
    }
    List<Tree> leaves = root.getLeaves();

    int firstNodeNum = nodes.get(0).index;

    Tree prevNode = firstNodeNum > 0 ? leaves.get(--firstNodeNum) : null;

    StringBuilder feature = new StringBuilder();

    feature.append("conn:");
    feature.append(connStr);
    feature.append(' ');

    feature.append("conn_POS:");
    feature.append(POS);
    feature.append(' ');

    if (!connStr.contains("..")) {

      int pos = nodes.get(0).index;
      if (pos <= 2) {
        feature.append("sent_pos:");
        feature.append(pos);
        feature.append(' ');
      } else {
        pos = nodes.get(nodes.size() - 1).index;
        if (pos >= leaves.size() - 3) {
          int pos2 = pos - leaves.size();
          feature.append("sent_pos:");
          feature.append(pos2);
          feature.append(' ');
        }
      }

      if (prevNode != null) {
        while (prevNode.parent(root).value().equals("-NONE-") && firstNodeNum > 0) {
          prevNode = leaves.get(--firstNodeNum);
        }

        if (prevNode != null) {

          String prevPOS = prevNode.parent(root).value().replace(' ', '_');
          String prev = prevNode.value().replace(' ', '_');

          feature.append("prev1:");
          feature.append(prev);
          feature.append(' ');

          feature.append("prev1_POS:");
          feature.append(prevPOS);
          feature.append(' ');

          feature.append("with_prev1_full:");
          feature.append(prev);
          feature.append('_');
          feature.append(connStr);
          feature.append(' ');

          feature.append("with_prev1_POS_full:");
          feature.append(prevPOS);
          feature.append('_');
          feature.append(POS);
          feature.append(' ');
          if (firstNodeNum > 0) {
            Tree prev2Node = leaves.get(--firstNodeNum);
            if (prev2Node != null) {
              while (prev2Node.parent(root).value().equals("-NONE-") && firstNodeNum > 0) {
                prev2Node = leaves.get(--firstNodeNum);
              }

              if (prev2Node != null) {
                String prev2POS = prev2Node.parent(root).value().replace(' ', '_');
                String prev2 = prev2Node.value().replace(' ', '_');

                feature.append("prev2:");
                feature.append(prev2);
                feature.append(' ');

                feature.append("prev2_POS:");
                feature.append(prev2POS);
                feature.append(' ');

                feature.append("with_prev2_full:");
                feature.append(prev2);
                feature.append('_');
                feature.append(connStr);
                feature.append(' ');

                feature.append("with_prev2_POS_full:");
                feature.append(prev2POS);
                feature.append('_');
                feature.append(POS);
                feature.append(' ');
              }
            }
          }
        }
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
    return outFile;
  }

}
