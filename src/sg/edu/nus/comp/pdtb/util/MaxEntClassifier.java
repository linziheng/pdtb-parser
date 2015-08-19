package sg.edu.nus.comp.pdtb.util;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;

import opennlp.maxent.BasicEventStream;
import opennlp.maxent.DataStream;
import opennlp.maxent.GIS;
import opennlp.maxent.GISModel;
import opennlp.maxent.PlainTextByLineDataStream;
import opennlp.maxent.io.SuffixSensitiveGISModelReader;
import opennlp.maxent.io.SuffixSensitiveGISModelWriter;
import opennlp.model.AbstractModel;
import opennlp.model.AbstractModelWriter;
import opennlp.model.EventStream;

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
 * 
 */

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class MaxEntClassifier {

  public static File createModel(File trainFile, String modelFilePath) throws IOException {
    File modelFile = new File(modelFilePath);

    FileReader datafr = new FileReader(trainFile);
    EventStream es = new BasicEventStream(new PlainTextByLineDataStream(datafr));
    AbstractModel model = GIS.trainModel(es, false);
    AbstractModelWriter writer = new SuffixSensitiveGISModelWriter(model, modelFile);
    writer.persist();

    return modelFile;
  }

  public static File predict(File testFile, File modelFile, File resultsFile)
      throws IOException {

    GISModel model = (GISModel) new SuffixSensitiveGISModelReader(modelFile).getModel();

    DataStream ds = new PlainTextByLineDataStream(new FileReader(testFile));
    PrintWriter results = new PrintWriter(resultsFile);
    while (ds.hasNext()) {
      String featureLine = (String) ds.nextToken();
      String[] features = featureLine.substring(0, featureLine.lastIndexOf(' ')).split(" ");
      double[] outcomes = model.eval(features);
      results.println(model.getAllOutcomes(outcomes) + "  " + model.getBestOutcome(outcomes));
    }
    results.close();

    return resultsFile;
  }
}
