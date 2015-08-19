package sg.edu.nus.comp.pdtb.model;

import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;

/**
 * Utility class for building and printing confusion matrix.
 * 
 * @author ilija.ilievski@u.nus.edu
 */
public class ConfusionMatrix {
  // TODO export to CSV
  // TODO charts
  // TODO better handling of the error propagation case

  /**
   * True to print doubles as percentages, i.e. 0.5532 would be 55.32 if PERCENTAGE is true.
   */
  private static final boolean PERCENTAGE = true;

  /**
   * Specify the number of digits printed after the decimal point for double numbers.
   */
  private static final int DECIMALS = 2;

  /**
   * The confusion matrix
   */
  private int[][] matrix;

  /**
   * Number of classes.
   */
  private int numClasses;

  /**
   * Class labels.
   */
  private String[] classes;

  /**
   * Longest label, used for formatted printing.
   */
  private int lngClass;

  /**
   * Longest value in the matrix, used for formatted printing.
   */
  private int lngValue;

  /**
   * Array with class total counts, used to print the matrix sorted on total counts.
   */
  private Pair[] classTotal;

  /**
   * Class to ID map.
   */
  private HashMap<String, Integer> classMap;

  /**
   * Total instances by now.
   */
  private int total;

  /**
   * @param N , is the total number of classes
   * @param classes , String array with all the classes.
   */
  public ConfusionMatrix(String[] classes) {

    this.classes = classes;
    this.numClasses = classes.length;
    this.lngClass = 5; // 5 for "Total" label
    this.lngValue = 0;
    this.total = 0;

    // Expected rows, predicted columns
    // +1 for total counts +1 column for class ID
    this.matrix = new int[numClasses + 1][numClasses + 1];

    this.classTotal = new Pair[numClasses];
    this.classMap = new HashMap<String, Integer>(numClasses + 1, 1.0f);

    for (int i = 0; i < numClasses; ++i) {
      classTotal[i] = new Pair(i, 0);
      classMap.put(classes[i], i);
      lngClass = Math.max(classes[i].length(), lngClass);
    }
  }

  /**
   * Checks if class contains before counting.
   * 
   * @param className
   * @return
   */
  public boolean containsClass(String className) {
    return classMap.containsKey(className);
  }

  /**
   * @param expected , expected, actual class
   * @param predicted , predicted class
   * @return current count for the pair
   * @throws NullPointerException if parameters are null or are unknown class.
   */
  public int count(String expected, String predicted) throws NullPointerException {
    Integer expId = classMap.get(expected);
    Integer prdId = classMap.get(predicted);

    if (expId == null) {
      System.out.println("ConfusionMatrix: Class " + expected + " is not in classMap.");
    }
    if (prdId == null) {
      System.out.println("ConfusionMatrix: Class " + predicted + " is not in classMap.");
    }
    // update counts
    ++matrix[expId][prdId];

    // update total counts
    ++matrix[numClasses][prdId];
    ++matrix[expId][numClasses];
    ++matrix[numClasses][numClasses];
    ++total;

    // for formatted printing
    int tmp = classTotal[expId].inc();
    tmp = Math.max(total, tmp);
    // +1 for space
    lngValue = Math.max(String.valueOf(tmp).length() + 1, lngValue);
    // must be odd number
    lngValue = lngValue % 2 == 0 ? lngValue + 1 : lngValue;

    return matrix[expId][prdId];
  }

  public double getRecallForClass(String className) {
    return getRecallForClass(classMap.get(className));
  }

  public double getRecallForClass(int classId) {
    int correct = matrix[classId][classId];
    double rowTotals = matrix[classId][numClasses];

    double recall = rowTotals == 0 ? 0 : correct / rowTotals;

    return recall;
  }

  public double getPrecisionForClass(String className) {
    return getPrecisionForClass(classMap.get(className));
  }

  public double getPrecisionForClass(int classId) {
    int correct = matrix[classId][classId];
    double colTotals = matrix[numClasses][classId];

    double precision = colTotals == 0 ? 0 : correct / colTotals;

    return precision;
  }

  public double getF_1ScoreForClass(String className) {
    return getF_1ScoreForClass(classMap.get(className));
  }

  public double getF_1ScoreForClass(int classId) {
    double precision = getPrecisionForClass(classId);
    double recall = getRecallForClass(classId);
    double F_1 = (precision + recall) == 0 ? 0 : (2 * precision * recall) / (precision + recall);

    return F_1;
  }

  public double getAccuracyForClass(String className) {
    return getAccuracyForClass(classMap.get(className));
  }

  public double getAccuracyForClass(int classId) {
    return getRecallForClass(classId);
  }

  public double getAccuracy() {
    int correct = 0;
    for (int i = 0; i < numClasses; ++i) {
      correct += matrix[i][i];
    }
    double total = matrix[numClasses][numClasses];

    double accuracy = total == 0 ? 0 : correct / (total);

    return accuracy;
  }

  private String printDouble(double num, int dec) {
    if (PERCENTAGE) {
      return String.format("%." + (dec) + "f", num * 100);
    } else {
      return String.format("%." + (dec + 2) + "f", num);
    }

  }

  private String printDouble(double num) {
    return printDouble(num, DECIMALS);
  }

  @Override
  public String toString() {
    return printByNatural() + printEvalMetrics();
  }

  /**
   * Print the matrix by the order passed to the constructor.
   * 
   * @return
   */
  public String printByNatural() {
    Arrays.sort(classTotal, new Comparator<Pair>() {

      @Override
      public int compare(Pair o1, Pair o2) {
        return o1.id - o2.id;
      }
    });

    StringBuilder sb = new StringBuilder(1000);
    sb.append("Printing ordered according to the class order passed to the constructor. \n");

    return print(sb);
  }

  /**
   * Print the matrix ordered by class name.
   * 
   * @return
   */
  public String printByClass() {
    Arrays.sort(classTotal, new Comparator<Pair>() {

      @Override
      public int compare(Pair o1, Pair o2) {
        return classes[o1.id].compareTo(classes[o2.id]);
      }
    });

    StringBuilder sb = new StringBuilder(1000);
    sb.append("Printing ordered by class names. \n");

    return print(sb);
  }

  /**
   * Print the matrix ordered by counts.
   * 
   * @return
   */
  public String printByCounts() {

    Arrays.sort(classTotal, new Comparator<Pair>() {

      @Override
      public int compare(Pair o1, Pair o2) {
        return o2.value - o1.value;
      }
    });

    StringBuilder sb = new StringBuilder(1000);
    sb.append("Printing ordered by class counts. \n");

    return print(sb);

  }

  private String print(StringBuilder sb) {
    sb.append("Matrix: \n");

    char label = 'A';
    sb.append(String.format("%1$" + (lngClass + 4) + "s", ""));// space for row labels

    // Print table header
    for (int i = 0; i < numClasses; ++i, ++label) {
      sb.append(String.format("%1$" + lngValue + "s", label));
    }
    sb.append(String.format("%1$" + lngValue + "s", 'T'));
    sb.append('\n');

    // Print rows
    label = 'A';
    for (int i = 0; i < numClasses; ++i, ++label) {
      sb.append(String.format("%1$" + lngClass + "s", classes[classTotal[i].id]));
      sb.append(" : ");
      sb.append(label);

      for (int j = 0; j < numClasses; ++j) {
        sb.append(String.format("%1$" + lngValue + "d", matrix[classTotal[i].id][classTotal[j].id]));
      }
      sb.append(String.format("%1$" + lngValue + "s", " " + classTotal[i].value));
      sb.append('\n');
    }

    // Print final row;
    sb.append(String.format("%1$" + lngClass + "s", "Total") + " : T");

    // total instances;
    for (int i = 0; i < numClasses + 1; ++i) {
      total += matrix[numClasses][i];
      sb.append(String.format("%1$" + lngValue + "d", matrix[numClasses][i]));
    }
    sb.append("\n");

    return sb.toString();
  }

  /**
   * Print evaluation metrics
   * 
   * @return
   */
  public String printEvalMetrics() {
    StringBuilder sb = new StringBuilder(1000);
    int tmpLng = Math.max(9, lngClass);// 9 for Macro-Avg
    sb.append(String.format("%1$" + (tmpLng + 3) + "s", ""));// space for row labels

    sb.append(String.format("%1$" + 10 + "s", "Precision"));
    sb.append(String.format("%1$" + 10 + "s", "Recall"));
    sb.append(String.format("%1$" + 10 + "s", "F_1 Score"));
    sb.append(String.format("%1$" + 10 + "s", "Count"));
    sb.append(String.format("%1$" + 10 + "s", "% of all"));
    sb.append('\n');

    for (int i = 0; i < numClasses; ++i) {
      sb.append(String.format("%1$" + tmpLng + "s", classes[classTotal[i].id]));
      sb.append(" : ");

      sb.append(String
          .format("%1$" + 10 + "s", printDouble(getPrecisionForClass(classTotal[i].id))));
      sb.append(String.format("%1$" + 10 + "s", printDouble(getRecallForClass(classTotal[i].id))));
      sb.append(String.format("%1$" + 10 + "s", printDouble(getF_1ScoreForClass(classTotal[i].id))));
      sb.append(String.format("%1$" + 10 + "s", classTotal[i].value));
      sb.append(String.format("%1$" + 10 + "s", printDouble(1.0 * classTotal[i].value
          / matrix[numClasses][numClasses])));
      sb.append('\n');
    }
    sb.append('\n');

    sb.append(String.format("%1$" + tmpLng + "s", "Macro-Avg"));
    sb.append(" : ");
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMacroPrecision())));
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMacroRecall())));
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMacroF_1Score())));
    sb.append(String.format("%1$" + 10 + "s", matrix[numClasses][numClasses]));
    sb.append('\n');

    sb.append(String.format("%1$" + tmpLng + "s", "Micro-Avg"));
    sb.append(" : ");
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMicroPrecision())));
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMicroRecall())));
    sb.append(String.format("%1$" + 10 + "s", printDouble(getMicroF_1Score())));
    sb.append(String.format("%1$" + 10 + "s", matrix[numClasses][numClasses]));
    sb.append('\n');
    sb.append(String.format("%1$" + tmpLng + "s", "Accuracy"));
    sb.append(" : ");
    sb.append(printDouble(getAccuracy()));
    sb.append('\n');

    return sb.toString();

  }

  private double getMicroF_1Score() {
    double precision = getMicroPrecision();
    double recall = getMicroRecall();
    double F_1 = (precision + recall) == 0 ? 0 : (2 * precision * recall) / (precision + recall);

    return F_1;
  }

  private double getMicroRecall() {
    double correctTotals = 0;
    double rowTotals = 0;

    for (int i = 0; i < numClasses; ++i) {
      correctTotals += matrix[i][i];
    }
    rowTotals = matrix[numClasses][numClasses] - matrix[numClasses - 1][numClasses];// noexp2exp

    double recall = rowTotals == 0 ? 0 : correctTotals / rowTotals;

    return recall;
  }

  private double getMicroPrecision() {
    double correctTotals = 0;
    double colTotals = 0;

    for (int i = 0; i < numClasses; ++i) {
      correctTotals += matrix[i][i];
    }
    colTotals += matrix[numClasses][numClasses] - matrix[numClasses][numClasses - 1];// exp2noexp

    double precision = colTotals == 0 ? 0 : correctTotals / colTotals;

    return precision;
  }

  public double getTrueMicro() {
    double correctTotals = 0;
    for (int i = 0; i < numClasses; ++i) {
      correctTotals += matrix[i][i];
    }
    double falsePositive = 0;
    for (int i = 0; i < numClasses; ++i) {
      falsePositive += matrix[i][numClasses];
    }

    double falseNegative = 0;
    for (int i = 0; i < numClasses; ++i) {
      falseNegative += matrix[numClasses][i];
    }

    double p = correctTotals / falsePositive;
    double r = correctTotals / falseNegative;
    double f1 = 2 * ((p * r) / (p + r));
    return f1;
  }

  private double getMacroRecall() {
    double macro = 0;

    for (int i = 0; i < classTotal.length; ++i) {
      macro += getRecallForClass(classTotal[i].id);
    }

    macro /= numClasses;

    return macro;
  }

  private double getMacroF_1Score() {
    double macro = 0;

    for (int i = 0; i < classTotal.length; ++i) {
      macro += getF_1ScoreForClass(classTotal[i].id);
    }

    macro /= numClasses;

    return macro;
  }

  private double getMacroPrecision() {
    double macro = 0;

    for (int i = 0; i < classTotal.length; ++i) {
      macro += getPrecisionForClass(classTotal[i].id);
    }

    macro /= numClasses;

    return macro;
  }

  /**
   * Used to keep the id order when sorting.
   * 
   * @author ilija
   */
  class Pair {

    int id;
    int value;

    Pair(int _id, int _value) {
      id = _id;
      value = _value;
    }

    public int inc() {
      return ++value;
    }

    @Override
    public String toString() {
      return "{" + id + ":" + value + "}";
    }
  }

  /**
   * Used for testing, since I didn't want to add the test module just for one class.
   * 
   * @param args
   */
  public static void main(String[] args) {
    String[] classes = {"Cat", "Dog", "Bird", "Cow", "Horse", "Fish"};
    ConfusionMatrix matrix = new ConfusionMatrix(classes);
    int[][] count =
        { {2, 3, 0, 0, 0, 0}, {7, 19, 1, 0, 0, 0}, {0, 0, 10, 4, 0, 0}, {0, 0, 0, 22, 1, 0},
            {0, 0, 0, 7, 24, 6}, {0, 0, 0, 0, 10, 30}};

    for (int i = 0; i < count.length; ++i) {
      for (int j = 0; j < count.length; ++j) {
        while (count[i][j] > 0) {
          matrix.count(classes[i], classes[j]);
          --count[i][j];
        }
      }
    }

    System.out.println(matrix.printByCounts());
    System.out.println(matrix.printEvalMetrics());
  }

}
