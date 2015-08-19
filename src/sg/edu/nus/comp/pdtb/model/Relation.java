/**
 * Copyright (C) 2014 WING, NUS and NUS NLP Group.
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

package sg.edu.nus.comp.pdtb.model;

import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkIsNumber;
import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkNotNull;
import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkRelType;
import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkTrueOrThrowError;

import java.util.regex.Pattern;

/**
 * /**
 * 
 * <pre>
 * The columns definition:
 * Col  0: Relation type (Explicit/Implicit/AltLex/EntRel/NoRel)
 * Col  1: Section number (0-24)
 * Col  2: File number (0-99)
 * Col  3: Connective/AltLex SpanList (only for Explicit and AltLex)
 * Col  4: Connective/AltLex GornAddressList (only for Explicit and AltLex)
 * Col  5: Connective/AltLex RawText (only for Explicit and AltLex)
 * Col  6: String position (only for Implicit, EntRel and NoRel) 
 * Col  7: Sentence number (only for Implicit, EntRel and NoRel)
 * Col  8: ConnHead (only for Explicit)
 * Col  9: Conn1 (only for Implicit)
 * Col 10: Conn2 (only for Implicit)
 * Col 11: 1st Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 * Col 12: 2nd Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 * Col 13: 1st Semantic Class corresponding to Conn2 (only for Implicit)
 * Col 14: 2nd Semantic Class corresponding to Conn2 (only for Implicit)
 * Col 15: Relation-level attribution: Source (only for Explicit, Implicit and AltLex)
 * Col 16: Relation-level attribution: Type (only for Explicit, Implicit and AltLex)
 * Col 17: Relation-level attribution: Polarity (only for Explicit, Implicit and AltLex)
 * Col 18: Relation-level attribution: Determinacy (only for Explicit, Implicit and AltLex)
 * Col 19: Relation-level attribution: SpanList (only for Explicit, Implicit and AltLex)
 * Col 20: Relation-level attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 * Col 21: Relation-level attribution: RawText (only for Explicit, Implicit and AltLex)
 * Col 22: Arg1 SpanList
 * Col 23: Arg1 GornAddress
 * Col 24: Arg1 RawText
 * Col 25: Arg1 attribution: Source (only for Explicit, Implicit and AltLex)
 * Col 26: Arg1 attribution: Type (only for Explicit, Implicit and AltLex)
 * Col 27: Arg1 attribution: Polarity (only for Explicit, Implicit and AltLex)
 * Col 28: Arg1 attribution: Determinacy (only for Explicit, Implicit and AltLex)
 * Col 29: Arg1 attribution: SpanList (only for Explicit, Implicit and AltLex)
 * Col 30: Arg1 attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 * Col 31: Arg1 attribution: RawText (only for Explicit, Implicit and AltLex)
 * Col 32: Arg2 SpanList
 * Col 33: Arg2 GornAddress
 * Col 34: Arg2 RawText
 * Col 35: Arg2 attribution: Source (only for Explicit, Implicit and AltLex)
 * Col 36: Arg2 attribution: Type (only for Explicit, Implicit and AltLex)
 * Col 37: Arg2 attribution: Polarity (only for Explicit, Implicit and AltLex)
 * Col 38: Arg2 attribution: Determinacy (only for Explicit, Implicit and AltLex)
 * Col 39: Arg2 attribution: SpanList (only for Explicit, Implicit and AltLex)
 * Col 40: Arg2 attribution: GornAddressList (only for Explicit, Implicit and AltLex)
 * Col 41: Arg2 attribution: RawText (only for Explicit, Implicit and AltLex)
 * Col 42: Sup1 SpanList (only for Explicit, Implicit and AltLex)
 * Col 43: Sup1 GornAddress (only for Explicit, Implicit and AltLex)
 * Col 44: Sup1 RawText (only for Explicit, Implicit and AltLex)
 * Col 45: Sup2 SpanList (only for Explicit, Implicit and AltLex)
 * Col 46: Sup2 GornAddress (only for Explicit, Implicit and AltLex)
 * Col 47: Sup2 RawText (only for Explicit, Implicit and AltLex)
 * </pre>
 * 
 * Example:
 * 
 * <pre>
 * Explicit|18|70|262..265|1,0|But|||but|||Comparison.Contrast||||Wr|Comm|Null|Null||||9..258|0|From a helicopter a thousand feet above Oakland after the second-deadliest earthquake in U.S. history, a scene of devastation emerges: a freeway crumbled into a concrete sandwich, hoses pumping water into once-fashionable apartments, abandoned autos|Inh|Null|Null|Null||||266..354|1,1;1,2;1,3|this quake wasn't the big one, the replay of 1906 that has been feared for so many years|Inh|Null|Null|Null|||||||||
 * </pre>
 * 
 * 
 * <pre>
 * Col 0: Relation type (Explicit/Implicit/AltLex/EntRel/NoRel)
 * Col 1: Section number (0-24)
 * Col 2: File number (0-99)
 * Col 7: Sentence number (only for Implicit, EntRel and NoRel)
 * </pre>
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class Relation implements Comparable<Relation> {
  // TODO add filename;
  // TODO make toString construct string from fields.

  public static final Type[] allTypes = {Type.ALT_LEX, Type.ENT_REL, Type.EXPLICIT, Type.IMPLICIT,
      Type.NO_REL};

  private static final Pattern SPLITTER = Pattern.compile("\\|");

  private String pipeLine;

  private Type type;

  /**
   * <p>
   * Range: [000-999]
   */
  private int section;

  /**
   * <p>
   * Range: [000-999]
   */
  private int fileNumber;

  /**
   * It's column 7 for Implicit, EntRel and NoRel relation types and Arg2 sentence number of first
   * tree for Explicit and AltLex.
   * <p>
   * Range: [0000-9999]
   * 
   */
  private int sentenceNumber;

  /**
   * It is <b>not</b> unique.
   * <p>
   * Check {@link Relation#generateKey()} to see how is calculated.
   */
  private long key;

  private Connective connective;
  private SemanticClass semanticClass;
  private Argument arg1;
  private Argument arg2;

  public Relation(String pipeLine) {

    checkNotNull(pipeLine);

    String[] columns = SPLITTER.split(pipeLine, -1);
    checkTrueOrThrowError(columns.length == 48, "Invalid columns length " + columns.length + ". "
        + pipeLine);

    this.pipeLine = pipeLine;

    checkRelType(columns[0]);
    this.type = Type.getType(columns[0]);

    checkIsNumber(columns[1], "section");
    this.section = Integer.parseInt(columns[1]);

    checkIsNumber(columns[2], "file number");
    this.fileNumber = Integer.parseInt(columns[2]);

    if (type.hasActualConnective()) {
      connective = new Connective(columns[5], columns[3], columns[4]);
    } else if (type == Type.IMPLICIT) {
      connective = new Connective(columns[9]);
    } else {
      connective = null;
    }

    semanticClass = new SemanticClass(columns[11], columns[12], columns[13], columns[14]);

    arg1 = new Argument(columns[24], columns[22], columns[23]);
    arg2 = new Argument(columns[34], columns[32], columns[33]);

    if (columns[7].isEmpty()) {

      checkTrueOrThrowError(type.hasActualConnective(),
          "Column 7 should be empty only for Explicit and AltLex.");
      this.sentenceNumber = arg2.getGornAddresses()[0][0];
    } else {
      checkIsNumber(columns[7], "sentence number");
      this.sentenceNumber = Integer.parseInt(columns[7]);
    }

    this.key = generateKey();
  }

  private long generateKey() {

    long textPos;
    if (type.hasActualConnective()) {
      textPos = sentenceNumber * 100_000 + connective.getSpanListRange()[0][0];
    } else {
      textPos = sentenceNumber;
    }

    long textPosPadding = 100_000_000_000l;
    long fileNumberPadding = 1000;
    long sectionPadding = 1000;
    long typePadding = 100;

    /* with {@code long} we have space for 19 digits */

    checkTrueOrThrowError(textPos < textPosPadding, " textPositon overflow");
    checkTrueOrThrowError(fileNumber < fileNumberPadding, " fileNumber overflow");
    checkTrueOrThrowError(section < sectionPadding, " section overflow");
    checkTrueOrThrowError(type.getId() < typePadding, " type overflow");

    fileNumberPadding *= textPosPadding;
    sectionPadding *= fileNumberPadding;

    // TODO does not work with improper sentences.
    // int[][] posNumbers;
    // try {
    // posNumbers = Util.getPositionNumbersForArticle(section, fileNumber);
    // Integer[] e = Util.getPositionForSpan(arg2.getSpanListRange(), posNumbers[0]);
    // textPos = e[0];
    // for (int i = 1; i < 4 && i < e.length; ++i) {
    // textPos += e[i] * 1000;
    // }
    // } catch (IOException e) {
    // e.printStackTrace();
    // }

    key =
        type.getId() * sectionPadding + section * fileNumberPadding + fileNumber * textPosPadding
            + textPos;

    return key;

  }

  @Override
  public int compareTo(Relation o) {
    return Long.compare(this.key, o.key);
  }

  @Override
  public boolean equals(Object anObject) {
    if (this == anObject) {
      return true;
    }
    if (anObject instanceof Relation) {
      Relation anotherRelation = (Relation) anObject;
      return pipeLine.equals(anotherRelation.pipeLine);
    }
    return false;
  }

  @Override
  public String toString() {
    return key + "    " + pipeLine;
  }

  @Override
  public int hashCode() {
    return pipeLine.hashCode();
  }

  public Type getType() {
    return type;
  }

  public int getSection() {
    return section;
  }

  public int getFileNumber() {
    return fileNumber;
  }

  public int getSentence() {
    return sentenceNumber;
  }

  public Connective getConnective() {
    return connective;
  }

  public SemanticClass getSemanticClass() {
    return semanticClass;
  }

  public Argument getArg1() {
    return arg1;
  }

  public Argument getArg2() {
    return arg2;
  }

  public String getPipeLine() {
    return pipeLine;
  }

  public long getKey() {
    return key;
  }
}
