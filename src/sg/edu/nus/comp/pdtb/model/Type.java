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

/**
 * Type of relations. The ID is used in key generation.
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public enum Type {
  ALT_LEX(0), ENT_REL(1), EXPLICIT(2), IMPLICIT(3), NO_REL(4);

  /**
   * Used in relation key generation.
   */
  private int id;

  /**
   * @param id
   */
  private Type(int id) {
    this.id = id;
  }

  /**
   * Checks if this relation type has actual, present in the text, connective.
   * 
   * <p>
   * Note that Implicit type of relations can have connective but this is a proposed connective, not
   * an actual one.
   * 
   * @return {@code true} if the type is AltLex or Explicit.
   */
  public boolean hasActualConnective() {
    //TODO only use EXPLICIT here
    //TODO have the connective for implicit, altlex and explicit just as additional info
    return (this.equals(ALT_LEX) || this.equals(EXPLICIT));
  }

  /**
   * Checks if this relation type has semantic class.
   * 
   * @return {@code true} if the type is AltLex, Explicit or Implicit.
   */
  public boolean hasSemanticClass() {
    return this.equals(ALT_LEX) || this.equals(EXPLICIT) || this.equals(IMPLICIT);
  }

  @Override
  public String toString() {
    switch (this) {
      case ALT_LEX:
        return "AltLex";
      case ENT_REL:
        return "EntRel";
      case EXPLICIT:
        return "Explicit";
      case IMPLICIT:
        return "Implicit";
      case NO_REL:
        return "NoRel";
      default:
        return null;
    }
  }

  public boolean equalsString(String type) {
    return this.toString().equals(type);
  }

  /**
   * Get type from string.
   * 
   * @param type
   * @return
   */
  public static Type getType(String type) {
    switch (type) {
      case "AltLex": {
        return Type.ALT_LEX;
      }
      case "EntRel": {
        return Type.ENT_REL;
      }
      case "Explicit": {
        return Type.EXPLICIT;
      }
      case "Implicit": {
        return Type.IMPLICIT;
      }
      case "NoRel": {
        return Type.NO_REL;
      }
      default: {
        return null;
      }
    }
  }

  public int getId() {
    return id;
  }

}
