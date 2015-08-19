/**
 * . * Copyright (C) 2014 WING, NUS and NUS NLP Group.
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

import static sg.edu.nus.comp.pdtb.util.ArgumentChecker.silentCheckIsNonEmpty;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import sg.edu.nus.comp.pdtb.util.Settings;
import sg.edu.nus.comp.pdtb.util.Util;

/**
 * <pre>
 * Col 11: 1st Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 * Col 12: 2nd Semantic Class  corresponding to ConnHead, Conn1 or AltLex span (only for Explicit, Implicit and AltLex)
 * Col 13: 1st Semantic Class corresponding to Conn2 (only for Implicit)
 * Col 14: 2nd Semantic Class corresponding to Conn2 (only for Implicit)
 * </pre>
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class SemanticClass {

  private String semanticClass1;
  private String semanticClass2;
  private String semanticClass3;
  private String semanticClass4;

  private String[] nonEmptyClasses;
  private Set<String> uniqueClasses;
  private List<String> nonEmptyList;

  @Override
  public String toString() {
    return Arrays.toString(getNonEmptyClasses());
  }

  public SemanticClass(String semanticClass1, String semanticClass2, String semanticClass3,
      String semanticClass4) {
    this.semanticClass1 = semanticClass1;
    this.semanticClass2 = semanticClass2;
    this.semanticClass3 = semanticClass3;
    this.semanticClass4 = semanticClass4;

    // to be lazy initialized
    this.nonEmptyClasses = null;
    this.uniqueClasses = null;
    this.nonEmptyList = null;
  }

  public String getSemanticClass1() {
    return semanticClass1;
  }

  public String getSemanticClass2() {
    return semanticClass2;
  }

  public String getSemanticClass3() {
    return semanticClass3;
  }

  public String getSemanticClass4() {
    return semanticClass4;
  }

  public String[] getNonEmptyClasses() {
    // even though this is not a thread safe check, it doesn't matter since
    // there is no harm in calling it multiple times.
    if (nonEmptyClasses == null) {
      List<String> list = getNonEmptyList();
      nonEmptyClasses = list.toArray(new String[list.size()]);
    }
    return nonEmptyClasses;
  }

  public Set<String> getUniqueClasses() {
    // even though this is not a thread safe check, it doesn't matter since
    // there is no harm in calling it multiple times.
    if (uniqueClasses == null) {
      uniqueClasses = new HashSet<String>();
      uniqueClasses.addAll(getNonEmptyList());
    }
    return uniqueClasses;
  }

  public List<String> getNonEmptyList() {

    if (nonEmptyList == null) {
      nonEmptyList = new ArrayList<>(4);

      if (silentCheckIsNonEmpty(semanticClass1)) {
        nonEmptyList.add(semanticClass1);
      }
      if (silentCheckIsNonEmpty(semanticClass2)) {
        nonEmptyList.add(semanticClass2);
      }
      if (silentCheckIsNonEmpty(semanticClass3)) {
        nonEmptyList.add(semanticClass3);
      }
      if (silentCheckIsNonEmpty(semanticClass4)) {
        nonEmptyList.add(semanticClass4);
      }
    }
    return nonEmptyList;
  }

  /**
   * At least one semantic class should match.
   * 
   * @param other
   * @return
   */
  public boolean match(SemanticClass other) {

    String[] thisSemantics = this.getNonEmptyClasses();
    String[] otherSemantics = other.getNonEmptyClasses();

    for (int i = 0; i < thisSemantics.length; ++i) {
      // TODO change how the semantic level is handled, maybe move that function to this class.
      String thisSemantic = Util.extractSemantic(thisSemantics[i], Settings.SEMANTIC_LEVEL);
      if (thisSemantic != null && thisSemantic.length() > 0) {
        for (int j = 0; j < otherSemantics.length; ++j) {
          String otherSemantic = Util.extractSemantic(otherSemantics[j], Settings.SEMANTIC_LEVEL);
          if (otherSemantic != null && otherSemantic.length() > 0) {
            if (thisSemantic.equals(otherSemantic)) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

}
