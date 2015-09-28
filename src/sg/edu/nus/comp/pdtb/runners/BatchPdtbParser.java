package sg.edu.nus.comp.pdtb.runners;

import java.io.File;
import java.io.IOException;
import java.util.Stack;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import sg.edu.nus.comp.pdtb.util.Settings;

public class BatchPdtbParser {
	private static Logger log = LogManager.getLogger(BatchPdtbParser.class.toString());

	public static void main(String[] args) throws IOException {
		if (args.length > 0) {
			File corpusDir = new File(args[0]);

			Stack<File> dirs = new Stack<>();
			dirs.add(corpusDir);
			while (dirs.size() > 0) {
				File currentDir = dirs.pop();
				log.info("Working in " + currentDir);
				File[] files = currentDir.listFiles();
				for (File file : files) {
					if (file.isDirectory()) {
						log.info("Adding directory " + file + " to queue.");
						dirs.push(file);
					} else {
						if (file.getName().endsWith(".txt")) {
							Settings.TMP_PATH = file.getParentFile().getAbsolutePath() + "/pdtb_"
									+ Settings.SEMANTIC_LEVEL + "/";
							File outDir = new File(Settings.TMP_PATH);
							if (!(outDir).exists()) {
								outDir.mkdirs();
							}
							if (!(new File(Settings.TMP_PATH + file.getName() + ".pipe").exists())) {
								log.info("Parsing file " + file);
								PdtbParser.parseFile(file, true);
							} else {
								log.info("Pipe aldready exists, skipping " + file);
							}
						}
					}
				}
			}
		} else {
			log.error("Please supply corpus directory as program argument.");
		}
	}
}
