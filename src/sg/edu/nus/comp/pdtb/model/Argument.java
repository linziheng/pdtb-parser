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
 * For now same as connective, but in future can be upgrade to include attribution.
 * 
 * <pre>
 * Col 22: Arg1 SpanList
 * Col 23: Arg1 GornAddress
 * Col 24: Arg1 RawText
 * 
 * Col 32: Arg2 SpanList
 * Col 33: Arg2 GornAddress
 * Col 34: Arg2 RawText
 * </pre>
 * 
 * @author ilija.ilievski@u.nus.edu
 * @since 0.5
 */
public class Argument extends TextSpan {

  public Argument(String rawText, String spanList, String gornAddressList) {
    super(rawText, spanList, gornAddressList);
  }

}
