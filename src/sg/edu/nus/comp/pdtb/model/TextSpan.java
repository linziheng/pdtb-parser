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

import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.checkNotNull;

import java.util.Arrays;

import sg.edu.nus.comp.pdtb.util.Util;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class TextSpan {

  private String spanList;

  /**
   * The span list string as int range.
   * 
   * <p>
   * For example:
   * <li>10..15 would be int matrix with one row and two columns {10,15}.
   * <li>10..15;20..25 would be int matrix with two rows and two columns {{10,15},{20,25}}
   * 
   */
  private int[][] spanListRange;

  /**
   * A <b>single</b> Gorn address {@code a1, a2, ... an−1, an} denotes the {@code anth} child of the
   * {@code an−1th} child of ... the {@code a2th} child of the sentence number {@code a1} in the
   * associated PTB file, and {@code T(a1, a2, ... an)} denotes the subtree rooted at an.
   * 
   */
  private String gornAddressList;

  /**
   * Matrix of Gorn address where each row contains one address. The first column contains the
   * sentence number. See {@link TextSpan#gornAddressList} for definition of Gorn address.
   */
  private int[][] gornAddresses;

  private String rawText;

  public TextSpan(String rawText, String spanList, String gornAddressList) {

    checkNotNull(rawText);
    checkNotNull(gornAddressList);
    checkNotNull(spanList);

    this.rawText = rawText.trim();

    this.spanList = spanList;
    this.spanListRange = Util.getSpanListRange(spanList);

    this.gornAddressList = gornAddressList;
    this.gornAddresses = Util.getGornAddresses(gornAddressList);
  }

  public TextSpan(String rawText) {
    this.rawText = rawText.trim();
    this.spanList = null;
    this.spanListRange = null;
    this.gornAddresses = null;
    this.gornAddressList = null;
  }

  public boolean match(TextSpan other) {

    int[] thisOffset = Util.getPunctuationOffset(this.rawText);
    int[] otherOffset = Util.getPunctuationOffset(other.rawText);

    String thisText = this.rawText.substring(thisOffset[0], this.rawText.length() - thisOffset[1]);
    String otherText =
        other.rawText.substring(otherOffset[0], other.rawText.length() - otherOffset[1]);

    if (thisText.equals(otherText)) {
      int[] thisRange = Util.offsetRange(this.spanListRange, thisOffset);
      int[] otherRange = Util.offsetRange(other.spanListRange, otherOffset);

      return Arrays.equals(thisRange, otherRange);
    }

    return false;
  }

  @Override
  public String toString() {
    return "Raw Text:\"" + rawText + "\" [SPAN:(" + spanList + "),GORN:(" + gornAddressList + ")]";
  }

  public String getSpanList() {
    return spanList;
  }

  public int[][] getSpanListRange() {
    return spanListRange;
  }

  public String getGornAddressList() {
    return gornAddressList;
  }

  /**
   * Matrix of Gorn address where each row contains one address. The first column contains the
   * sentence number. See {@link TextSpan#gornAddressList} for definition of Gorn address.
   */
  public int[][] getGornAddresses() {
    return gornAddresses;
  }

  public String getRawText() {
    return rawText;
  }

}
