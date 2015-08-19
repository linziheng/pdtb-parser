/**
 * Copyright (C) 2015 WING, NUS and NUS NLP Group.
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

/**
 * Static class to hold parser configuration variables.
 * 
 * @author ilija.ilievski@u.nus.edu
 */
public class Settings extends NestedProperties {

  /**
   * Train sections.
   */
  public static int[] TRAIN_SECTIONS;

  /**
   * Test sections.
   */
  public static int[] TEST_SECTIONS;

  /**
   * Relation semantic sense evaluation level.
   */
  public static int SEMANTIC_LEVEL;

  /**
   * Path to the PDTB corpus.
   */
  public static String PDTB_PATH;

  /**
   * Training parse tree directory.
   */
  public static String PTB_TREE_PATH;

  /**
   * Automatic parse tree directory.
   */
  public static String PTB_AUTO_TREE_PATH;

  /**
   * Automatic parse tree directory for the non-explicit component.
   */
  public static String PTB_NONEXP_TREES_PATH;

  /**
   * Training dependency tree directory.
   */
  public static String DEPEND_TREE_PATH;

  /**
   * Automatic dependency tree directory.
   */
  public static String DEPEND_AUTO_TREE_PATH;

  /**
   * Raw article text files.
   */
  public static String PTB_RAW_PATH;

  /**
   * Paragraph information path (auxiliary data).
   */
  public static String PARA_PATH;

  /**
   * Sentence information path (auxiliary data).
   */
  public static String SENT_MAP_PATH;

  /**
   * Auxiliary data for the non-explicit component.
   */
  public static String PROD_RULES_FILE;

  /**
   * Auxiliary data for the non-explicit component.
   */
  public static String DEP_RULES_FILE;

  /**
   * Auxiliary data for the non-explicit component.
   */
  public static String WORD_PAIRS_FILE;

  /**
   * Directory for output of the argument extractor component, used for error propagation.
   */
  public static String ARG_EXT_EP;

  /**
   * Directory for output of the argument extractor component, used for error propagation.
   */
  public static String ARG_EXT_AUTO;

  /**
   * Directory for the generated parse and dependency trees generated when parsing free text.
   */
  public static String TMP_PATH;

  /**
   * Results directory.
   */
  public static String OUT_PATH;
}
