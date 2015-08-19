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

package sg.edu.nus.comp.pdtb.util;

import sg.edu.nus.comp.pdtb.model.Type;

/**
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class ArgumentChecker {
  // TODO allow for partial scoring

  public static boolean checkRelType(String type) {
    checkNotNull(type);

    Type aType = Type.getType(type);

    if (aType == null) {
      throw new IllegalArgumentException(type + " is not a valid relation type.");
    } else {
      return true;
    }
  }

  /**
   * Ensures that an object reference passed as a parameter to the calling method is not null.
   *
   * @param reference an object reference
   * @return true if not null
   * @throws NullPointerException if {@code reference} is null
   */
  public static boolean checkNotNull(Object reference) {
    if (reference == null) {
      throw new NullPointerException();
    } else {
      return true;
    }
  }

  public static boolean checkTrueOrThrowError(boolean condition, String errorMessage) {
    if (!condition) {
      throw new IllegalArgumentException(errorMessage);
    } else {
      return true;
    }
  }

  public static boolean checkIsNumber(String number, String message) throws NumberFormatException {
    try {
      Integer.parseInt(number);
    } catch (NumberFormatException e) {
      throw new NumberFormatException("For " + message + ", it was: " + number);
    }
    return true;
  }

  public static boolean silentCheckIsNonEmpty(String aString) {
    return aString != null && !aString.isEmpty();
  }

}
