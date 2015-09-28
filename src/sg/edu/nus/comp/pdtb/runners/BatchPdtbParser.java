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
				File[] files = currentDir.listFiles();
				int num = 0;
				for (File file : files) {
					if (file.isDirectory()) {
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
								PdtbParser.parseFile(file, true);
							} else {
								log.trace("Skipping " + file.getName());
							}
						}
					}
					++num;
					log.trace((int) (100.0 * num / files.length) + "% done");
				}
			}
		} else {
			log.error("Please supply corpus directory as program argument.");
		}
	}
}
