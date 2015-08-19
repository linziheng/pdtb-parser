package sg.edu.nus.comp.pdtb.util;

/**
 * 
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
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import sg.edu.nus.comp.pdtb.model.FeatureType;

/**
 * Methods for reproducing Lin et al., JNLE 2014 paper results without using the PDTB corpus.
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class Scorer {

  public static class Result {
    public double prec;
    public double recall;
    public double f1;
    public double acc;

    Result(double p, double r, double f1, double acc) {
      prec = p;
      recall = r;
      this.f1 = f1;
      this.acc = acc;
    }

    public String print(double num) {
      return String.format("%.2f", num);
    }

    public String printAll() {
      return "Prec\tRecall\tF1\n" + print(prec) + " " + print(recall) + " " + print(f1);
    }
  }

  public static Result conn(File gsFile, File pdFile) throws IOException {

    int[] counts = countConn(gsFile, pdFile);

    int tp = counts[0], fn = counts[1], fp = counts[2], tn = counts[3];

    double p = (tp + fp) == 0 ? 0 : tp * 100.0 / (tp + fp);
    double r = (tp + fn) == 0 ? 0 : tp * 100.0 / (tp + fn);
    double f1 = (p + r) == 0 ? 0 : 2 * p * r / (p + r);
    double acc = (tp + tn) * 100.0 / (tp + fp + fn + tn);

    return new Result(p, r, f1, acc);
  }

  public static Result argPos(File gsFile, File pdFile, FeatureType featureType) throws IOException {

    int correct = countMatches(gsFile, pdFile);

    double gsTotal = 923;
    double prdTotal = 923;
    if (featureType == FeatureType.ErrorPropagation) {
      prdTotal = 918;
    }
    if (featureType == FeatureType.Auto) {
      prdTotal = 912;
    }

    return calcResults(gsTotal, prdTotal, correct);
  }

  public static Result exp(File gsFile, File pdFile, FeatureType featureType) throws IOException {

    int correct = countSenseTypes(gsFile, pdFile);

    double gsTotal = 922;
    double prdTotal = 922;

    if (featureType == FeatureType.ErrorPropagation) {
      prdTotal = 917;
    }
    if (featureType == FeatureType.Auto) {
      prdTotal = 911;
    }

    Result score = calcResults(gsTotal, prdTotal, correct);
    return score;
  }

  public static Result nonExp(File gsFile, File pdFile, FeatureType featureType) throws IOException {

    int correct = countSenseTypes(gsFile, pdFile);

    double gsTotal = 1017;
    double prdTotal = 1017;

    if (featureType == FeatureType.ErrorPropagation) {
      prdTotal = 1093;
    }
    if (featureType == FeatureType.Auto) {
      prdTotal = 1096;
    }

    Result score = calcResults(gsTotal, prdTotal, correct);
    return score;
  }

  private static int countSenseTypes(File expFile, File prdFile) throws IOException {
    int c = 0;
    try (BufferedReader reader =
        new BufferedReader(new InputStreamReader(new FileInputStream(expFile), Util.ENCODING))) {
      try (BufferedReader read =
          new BufferedReader(new InputStreamReader(new FileInputStream(prdFile), Util.ENCODING))) {
        String eTmp;
        String pTmp;
        while ((eTmp = reader.readLine()) != null) {
          pTmp = read.readLine();
          String[] exp = eTmp.split("\\s+");
          String[] prd = pTmp.split("\\s+");
          String[] tmp = exp[exp.length - 1].split("£");

          if (tmp[0].equals(prd[prd.length - 1])
              || (tmp.length > 1 && tmp[1].equals(prd[prd.length - 1]))) {
            ++c;
          }
        }
      }
    }

    return c;
  }

  private static int countMatches(File gsFile, File pdFile) throws IOException {
    int c = 0;
    try (BufferedReader eR =
        new BufferedReader(new InputStreamReader(new FileInputStream(gsFile), Util.ENCODING))) {
      try (BufferedReader pR =
          new BufferedReader(new InputStreamReader(new FileInputStream(pdFile), Util.ENCODING))) {
        String eTmp;
        String pTmp;
        while ((pTmp = pR.readLine()) != null) {
          eTmp = eR.readLine();

          String[] exp = eTmp.split("\\s+");
          String[] prd = pTmp.split("\\s+");
          if (exp[exp.length - 1].equals(prd[prd.length - 1])) {
            ++c;
          }
        }
      }
    }
    return c;
  }

  private static int[] countConn(File gsFile, File pdFile) throws IOException {
    int tp = 0, fn = 0, fp = 0, tn = 0;

    try (BufferedReader gsRead =
        new BufferedReader(new InputStreamReader(new FileInputStream(gsFile), Util.ENCODING))) {
      try (BufferedReader pdRead =
          new BufferedReader(new InputStreamReader(new FileInputStream(pdFile), Util.ENCODING))) {
        String expected;
        while ((expected = gsRead.readLine()) != null) {
          String predicted = pdRead.readLine();
          expected = " " + expected;
          int expConn = Integer.parseInt(expected.substring(expected.lastIndexOf(' ')).trim());
          int prdConn = Integer.parseInt(predicted.substring(predicted.lastIndexOf(' ')).trim());

          if (prdConn == 1 && expConn == 1) {
            ++tp;
          } else if (prdConn == 0 && expConn == 1) {
            ++fn;
          } else if (prdConn == 1 && expConn == 0) {
            ++fp;
          } else if (prdConn == 0 && expConn == 0) {
            ++tn;
          }
        }
      }
    }

    return new int[] {tp, fn, fp, tn};
  }

  private static Result calcResults(double gsTotal, double prdTotal, int correct) {

    double p = prdTotal == 0 ? 0 : (1.0 * correct / prdTotal) * 100;
    double r = gsTotal == 0 ? 0 : (1.0 * correct / gsTotal) * 100;
    double f1 = (2 * p * r) / (r + p);

    return new Result(p, r, f1, -1);
  }

  public static Result[] argExtExact(File resultPipeFile, FeatureType featureType)
      throws IOException {
    int arg1Correct = 0;
    int arg2Correct = 0;
    int bothCorrect = 0;
    try (BufferedReader reader =
        new BufferedReader(
            new InputStreamReader(new FileInputStream(resultPipeFile), Util.ENCODING))) {
      String line;
      while ((line = reader.readLine()) != null) {
        String[] args = line.split("\\|", -1);
        boolean arg1Match = args[4].equals(args[6]) || exactMatch(args[0], args[2]);
        boolean arg2Match = args[5].equals(args[7]) || exactMatch(args[1], args[3]);
        if (arg1Match) {
          ++arg1Correct;
        }
        if (arg2Match) {
          ++arg2Correct;
        }
        if (arg1Match && arg2Match) {
          ++bothCorrect;
        }
      }
    }

    double gsTotal = 923;
    double prdTotal = 923;
    if (featureType == FeatureType.ErrorPropagation) {
      prdTotal = 918;
    }
    if (featureType == FeatureType.Auto) {
      prdTotal = 912;
    }

    return new Result[] {calcResults(gsTotal, prdTotal, arg1Correct),
        calcResults(gsTotal, prdTotal, arg2Correct), calcResults(gsTotal, prdTotal, bothCorrect)};
  }

  private static boolean exactMatch(String expected, String predicted) {

    expected = regexSafe(expected);
    predicted = regexSafe(predicted);
    String eStriped = expected.replaceAll(predicted, "").trim();
    String pStriped = predicted.replaceAll(expected, "").trim();
    String[] eParts = eStriped.split("\\b");
    String[] pParts = pStriped.split("\\b");
    if (((eParts.length == 1) && !eStriped.equals(expected.trim()))
        || ((pParts.length == 1) && !pStriped.equals(predicted.trim()))) {
      return true;
    }
    return false;
  }

  public static boolean partMatch(String expected, String predicted) {

    expected = regexSafe(expected);
    predicted = regexSafe(predicted);
    String[] eParts = expected.split("\\b");
    String[] pParts = predicted.split("\\b");

    for (String eWord : eParts) {
      for (String pWord : pParts) {
        if (eWord.equals(pWord)) {
          return eWord.length() > 1;
        }
      }
    }

    return false;
  }

  private static String regexSafe(String string) {
    return string.replaceAll("\\{|\\}|\\[|\\]|\\(|\\)|\\&", "").trim();
  }

  public static Result[] argExtPartial(File resultPipeFile, FeatureType featureType)
      throws IOException {
    int arg1Correct = 0;
    int arg2Correct = 0;
    int bothCorrect = 0;
    try (BufferedReader reader =
        new BufferedReader(
            new InputStreamReader(new FileInputStream(resultPipeFile), Util.ENCODING))) {
      String line;
      while ((line = reader.readLine()) != null) {
        String[] args = line.split("\\|", -1);
        boolean arg1Match = args[4].equals(args[6]) || partMatch(args[0], args[2]);
        boolean arg2Match = args[5].equals(args[7]) || partMatch(args[1], args[3]);
        if (arg1Match) {
          ++arg1Correct;
        }
        if (arg2Match) {
          ++arg2Correct;
        }
        if (arg1Match && arg2Match) {
          ++bothCorrect;
        }
      }
    }

    double gsTotal = 923;
    double prdTotal = 923;
    if (featureType == FeatureType.ErrorPropagation) {
      prdTotal = 918;
    }
    if (featureType == FeatureType.Auto) {
      prdTotal = 912;
    }

    return new Result[] {calcResults(gsTotal, prdTotal, arg1Correct),
        calcResults(gsTotal, prdTotal, arg2Correct), calcResults(gsTotal, prdTotal, bothCorrect)};
  }
}
