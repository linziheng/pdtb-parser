package sg.edu.nus.comp.pdtb.model;

import edu.stanford.nlp.trees.Tree;

/**
 * Class that associates tree node with it's tree root in order to be able to get it's unique node
 * number. The unique node number is needed while generating the dependency tree features.
 * 
 * @author ilija.ilievski@u.nus.edu
 */
public class TreeNode {

  /**
   * 
   */
  private Tree root;

  /**
   * 
   */
  private Tree node;

  /**
   * Tree number corresponds to the sentence number in the article.
   */
  private int treeNumber;

  /**
   * 
   * @param root
   * @param node
   * @param treeNumber
   */
  public TreeNode(Tree root, Tree node, int treeNumber) {
    this.root = root;
    this.treeNumber = treeNumber;
    this.node = node;
  }

  /**
   * @return the root
   */
  public Tree getRoot() {
    return root;
  }

  /**
   * @param root the root to set
   */
  public void setRoot(Tree root) {
    this.root = root;
  }

  /**
   * @return the node
   */
  public Tree getNode() {
    return node;
  }

  /**
   * @param node the node to set
   */
  public void setNode(Tree node) {
    this.node = node;
  }

  /**
   * @return the treeNumber
   */
  public int getTreeNumber() {
    return treeNumber;
  }

  /**
   * @param treeNumber the treeNumber to set
   */
  public void setTreeNumber(int treeNumber) {
    this.treeNumber = treeNumber;
  }


}
