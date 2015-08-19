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

public enum FeatureType {
  GoldStandard, ErrorPropagation, Auto, Training, AnyText;

  public static FeatureType[] testingValues() {
    return new FeatureType[] {GoldStandard, ErrorPropagation, Auto};
  }

  @Override
  public String toString() {
    String string = "";
    switch (this) {
      case Training:
        string = ".train";
        break;
      case GoldStandard:
        string = ".gs";
        break;
      case ErrorPropagation:
        string = ".gs.ep";
        break;
      case Auto:
        string = ".auto.ep";
        break;
      case AnyText:
        string = ".res";
        break;
    }

    return string;
  }
}
