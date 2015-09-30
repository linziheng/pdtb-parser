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

import static sg.edu.nus.comp.pdtb.util.Util.getStaticFields;
import static sg.edu.nus.comp.pdtb.util.Util.toIntArray;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Static class for reading nested properties from a file.
 * 
 * @author ilija.ilievski@u.nus.edu
 *
 */
public class NestedProperties {

	private static Logger log = LogManager.getLogger(NestedProperties.class);

	/**
	 * Configuration file name.
	 */
	private static final String PROPERTIES_PATH = "config.properties";

	/**
	 * Load properties.
	 */
	static {
		try (InputStream input = new FileInputStream(PROPERTIES_PATH)) {
			log.info("Loading properties from: " + PROPERTIES_PATH);
			Map<String, Field> classFields = getStaticFields(Settings.class);
			Properties prop = new Properties();
			prop.load(input);
			Set<Object> keySet = prop.keySet();
			for (Object keyObj : keySet) {
				String key = keyObj.toString();
				String value = prop.getProperty(key);
				log.trace("Resolving property: " + value);
				value = resolveValue(prop, value);

				if (classFields.containsKey(key)) {
					Field field = classFields.get(key);
					setFieldValue(field, value);
					log.info(field.getName() + " : " + value);
				}
			}
			log.info("Done loading properties.");

		} catch (IOException | SecurityException | IllegalArgumentException | IllegalAccessException e) {
			e.printStackTrace();
		}
	}

	private static void setFieldValue(Field field, String value)
			throws NumberFormatException, IllegalArgumentException, IllegalAccessException {

		if (field.getType().equals(int.class)) {
			field.set(null, Integer.valueOf(value.trim()));
		} else if (field.getType().equals(int[].class)) {
			int[] intArray = toIntArray(value);
			field.set(null, intArray);
		} else if (field.getType().equals(String.class)) {
			field.set(null, value);
		} else {
			log.error("Field " + field.getName() + " is of unknown class", new IllegalArgumentException());
		}
	}

	private static String resolveValue(Properties prop, String value) {

		while (value.matches(".*\\{.+\\}.*")) {

			String variable = value.substring(value.indexOf('{') + 1, value.indexOf('}')).trim();
			String varValue = prop.getProperty(variable);

			if (varValue == null) {
				log.error("Invalid nested variable " + variable + " in file: " + PROPERTIES_PATH,
						new IllegalArgumentException());
			} else {
				value = value.replace("{" + variable + "}", varValue.trim());
			}
		}

		return value;
	}
}
