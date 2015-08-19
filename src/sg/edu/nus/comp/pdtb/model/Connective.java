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
 * <pre>
 * Col 3: Connective/AltLex SpanList (only for Explicit and AltLex)
 * Col 4: Connective/AltLex GornAddressList (only for Explicit and AltLex)
 * Col 5: Connective/AltLex RawText (only for Explicit and AltLex)
 * </pre>
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class Connective extends TextSpan {

  public Connective(String rawText, String spanList, String gornAddressList) {
    super(rawText, spanList, gornAddressList);
  }

  public Connective(String rawText) {
    super(rawText);
  }

}
