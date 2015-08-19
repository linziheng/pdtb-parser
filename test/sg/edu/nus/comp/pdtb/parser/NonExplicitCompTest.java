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

package sg.edu.nus.comp.pdtb.parser;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.SynchronousQueue;

import junit.framework.TestCase;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;
import sg.edu.nus.comp.pdtb.model.FeatureType;
import sg.edu.nus.comp.pdtb.util.Corpus;
import sg.edu.nus.comp.pdtb.util.Settings;

public class NonExplicitCompTest extends TestCase {

  private static Logger log = LogManager.getLogger(NonExplicitCompTest.class.getName());

  /**
   * Test method for {@link sg.edu.nus.comp.pdtb.parser.NonExplicitComp#buildDependencyTrees()}
   * 
   * @throws IOException
   */
  @Test
  public final void testBuildDependencyTrees_TrainSect() throws IOException {

    NonExplicitComp comp = new NonExplicitComp();
    FeatureType featureType = FeatureType.Training;
    log.info("Testing buildDependencyTrees on Train Sections");
    for (int section : Settings.TRAIN_SECTIONS) {
      File[] files = Corpus.getSectionFiles(section);
      for (File article : files) {
        log.info(article.getName());
        comp.initTrees(article, featureType);
        comp.buildDependencyTrees(article, featureType);
      }
    }
    assertEquals(comp.getDtreeMap().size(), 1453);
  }

  /**
   * Test method for {@link sg.edu.nus.comp.pdtb.parser.NonExplicitComp#buildDependencyTrees()}
   * 
   * @throws IOException
   */
  @Test
  public final void testBuildDependencyTrees_TestSect() throws IOException {

    NonExplicitComp comp = new NonExplicitComp();
    FeatureType featureType = FeatureType.Auto;

    for (int section : Settings.TEST_SECTIONS) {
      File[] files = Corpus.getSectionFiles(section);
      for (File article : files) {
        log.info(article.getName());
        comp.initTrees(article, featureType);
        comp.buildDependencyTrees(article, FeatureType.ErrorPropagation);
      }
    }

    assertEquals(comp.getDtreeMap().size(), 456);
  }
}
