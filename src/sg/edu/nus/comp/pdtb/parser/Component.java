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

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.MaxEntClassifier;
import sg.edu.nus.comp.pdtb.util.Settings;

/**
 * Common class for parser component.
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public abstract class Component {

  protected static Logger log = null;

  protected String name = "not_set";
  protected String modelFilePath;
  protected File modelFile;
  protected File gsFile;

  public Component(String name, String className) {
    log = LogManager.getLogger(className);
    this.name = name;
    this.modelFilePath = OUT_PATH + name + ".model";
    this.modelFile = new File(modelFilePath);
  }

  public abstract List<String[]> generateFeatures(File article, FeatureType featureType)
      throws IOException;

  public abstract File parseAnyText(File modelFile, File inputFile) throws IOException;

  public File parseAnyText(File inputFile) throws IOException {
    return parseAnyText(modelFile, inputFile);
  };

  public File train() throws IOException {
    File trainFile = printFeaturesToFile(FeatureType.Training);
    File modelFile = MaxEntClassifier.createModel(trainFile, modelFilePath);
    return modelFile;
  }

  public File test(File model, FeatureType featureType) throws IOException {
    File testFile = printFeaturesToFile(featureType);
    String fileName = this.name + featureType.toString() + ".out";
    File outFile = MaxEntClassifier.predict(testFile, modelFile, new File(fileName));

    return outFile;
  }

  private File printFeaturesToFile(FeatureType featureType) throws IOException {
    String name = this.name + featureType.toString();
    File file = new File(OUT_PATH + name);
    PrintWriter featureFile = new PrintWriter(file);

    log.info("Printing " + featureType + " features: ");
    int[] sections =
        (featureType == FeatureType.Training) ? Settings.TRAIN_SECTIONS : Settings.TEST_SECTIONS;
    for (int section : sections) {
      log.info("Section: " + section);
      File[] files = Corpus.getSectionFiles(section);

      for (File article : files) {
        log.trace("Article: " + article.getName());
        List<String[]> features = generateFeatures(article, featureType);
        for (String[] feature : features) {
          featureFile.println(feature[0]);
        }
        featureFile.flush();
      }
    }
    featureFile.close();

    return file;
  }

  public File test(FeatureType featureType) throws IOException {
    return test(modelFile, featureType);
  }

  public File getModelFile() {
    return modelFile;
  }

  public File getGsFile() {
    return gsFile;
  }

  public File getGsFile(FeatureType type) {
    this.gsFile = new File(OUT_PATH + name + type);
    return gsFile;
  }

  public String getModelFilePath() {
    return this.modelFilePath;
  }

  public void setModelFilePath(String modelFilePath) {
    this.modelFilePath = modelFilePath;
  }
}
