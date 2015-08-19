package sg.edu.nus.comp.pdtb.model;

import java.util.ArrayList;
import java.util.List;

import edu.stanford.nlp.trees.Tree;

public class Dependency {
  Tree node;
  List<Integer> dependents;
  Tree dependsOn;
  String label;
  private Tree dtreeRoot;

  /**
   * @param node
   * @param dependents
   * @param dependsOn
   * @param label
   */
  public Dependency(Tree node, List<Integer> dependents, Tree dependsOn, String label) {
    super();
    this.node = node;
    this.dependents = dependents;
    this.dependsOn = dependsOn;
    this.label = label;
  }

  @Override
  public String toString() {
    return node.toString();
  }

  public Dependency(Tree node) {
    this.node = node;
    dependents = new ArrayList<Integer>();
    dependsOn = null;
    label = null;
    dtreeRoot = null;
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
   * @return the dependents
   */
  public List<Integer> getDependents() {
    return dependents;
  }

  /**
   * @param dependents the dependents to set
   */
  public void setDependents(List<Integer> dependents) {
    this.dependents = dependents;
  }

  /**
   * @return the dependsOn
   */
  public Tree getDependsOn() {
    return dependsOn;
  }

  /**
   * @param dependsOn the dependsOn to set
   */
  public void setDependsOn(Tree dependsOn) {
    this.dependsOn = dependsOn;
  }

  /**
   * @return the label
   */
  public String getLabel() {
    return label;
  }

  /**
   * @param label the label to set
   */
  public void setLabel(String label) {
    this.label = label;
  }

  /**
   * @return the dtreeRoot
   */
  public Tree getDtreeRoot() {
    return dtreeRoot;
  }

  /**
   * @param dtreeRoot the dtreeRoot to set
   */
  public void setDtreeRoot(Tree dtreeRoot) {
    this.dtreeRoot = dtreeRoot;
  }

  public void addDependents(int c) {
    if (dependents == null) {
      dependents = new ArrayList<Integer>();
    }
    dependents.add(c);
  }


}
