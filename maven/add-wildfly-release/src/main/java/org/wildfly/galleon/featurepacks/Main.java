/*
 * Copyright The WildFly Authors
 * SPDX-License-Identifier: Apache-2.0
 */
package org.wildfly.galleon.featurepacks;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.jboss.galleon.config.FeaturePackConfig;
import org.jboss.galleon.config.ProvisioningConfig;
import org.jboss.galleon.universe.FeaturePackLocation;
import org.jboss.galleon.util.IoUtils;
import org.jboss.galleon.xml.ProvisioningXmlParser;
import org.jboss.galleon.xml.ProvisioningXmlWriter;
import org.yaml.snakeyaml.Yaml;

public class Main {

    private static final String VERSION_PROP = "wildfly-version";
    private static final String BASE_DIR_PROP = "base-dir";

    private static Map<String, Set<String>> KNOWN_FEATURE_PACKS = new HashMap<>();

    public static void main(String[] args) throws Exception {
        String wildflyVersion = System.getProperty(VERSION_PROP);
        if (wildflyVersion == null) {
            throw new Exception("-D" + VERSION_PROP + "=<version> must be set");
        }
        String baseDir = System.getProperty(BASE_DIR_PROP);
        if (baseDir == null) {
            throw new Exception("-D" + BASE_DIR_PROP + "=<base dir> must be set");
        }
        Path baseDirPath = Paths.get(baseDir).toAbsolutePath().normalize();
        Path newWildFlyVersionDir = baseDirPath.resolve(wildflyVersion);
        if (Files.exists(newWildFlyVersionDir)) {
            throw new Exception("New version " + wildflyVersion + " already exists");
        }
        ObjectMapper mapper = new ObjectMapper();
        // identify Beta vs Final
        String[] split = wildflyVersion.split("\\.");
        int major = Integer.parseInt(split[0]);
        int minor = Integer.parseInt(split[1]);
        int micro = Integer.parseInt(split[2]);
        String stability = split[3];
        addVersion(baseDirPath, major, minor, micro, stability, wildflyVersion, false);
        Yaml yaml = new Yaml();
        Path spacesFile = baseDirPath.resolve("spaces/spaces.yaml");
        try (FileInputStream stream = new FileInputStream(spacesFile.toFile())) {
            Map<String, Object> obj = yaml.load(stream);
            List<Map<String, Object>> spaces = (List<Map<String, Object>>) obj.get("spaces");
            for (Map<String, Object> space : spaces) {
                String name = (String) space.get("name");
                System.out.println("Handling space " + name);
                Path spacePath = baseDirPath.resolve("spaces/" + name);
                addVersion(spacePath, major, minor, micro, stability, wildflyVersion, true);
            }
        }

        // Generate catalog
        Path catalogDir = baseDirPath.resolve("catalog/" + wildflyVersion);
        Files.createDirectories(catalogDir);
        Path origVariantFile = baseDirPath.resolve(wildflyVersion).resolve("variants.json");
        JsonNode variantNode = mapper.readTree(origVariantFile.toFile());
        ArrayNode nodes = (ArrayNode) variantNode.get("variants");
        for (Entry<String, Set<String>> entry : KNOWN_FEATURE_PACKS.entrySet()) {
            String variant = entry.getKey();
            Set<String> featurePacks = entry.getValue();
            Path variantDir;
            if (variant.equals("default")) {
                variantDir = catalogDir;
            } else {
                String variantDirName = variant;
                // Map from metadata directory to catalog directory name
                for (JsonNode node : nodes) {
                    JsonNode dirNode = node.get("directory");
                    if (dirNode != null && dirNode.asText().equals(variant)) {
                        variantDirName = node.get("name").asText();
                        break;
                    }
                }
                variantDir = catalogDir.resolve(variantDirName);
                Files.createDirectories(variantDir);
            }
            Path featurePacksFile = variantDir.resolve("feature-packs.json");
            ObjectNode target = mapper.createObjectNode();
            ArrayNode fps = mapper.createArrayNode();
            for (String fp : featurePacks) {
                fps.add(fp);
            }
            target.set("featurePacks", fps);
            mapper.writerWithDefaultPrettyPrinter().writeValue(featurePacksFile.toFile(), target);
        }
        // Write the variants file used by the catalog
        Path variantFile = catalogDir.resolve("variants.json");
        for (JsonNode node : nodes) {
            ObjectNode mutable = (ObjectNode) node;
            mutable.remove("directory");
            String name = mutable.get("name").asText();
            mutable.remove("name");
            mutable.put("directory", name);
        }
        mapper.writerWithDefaultPrettyPrinter().writeValue(variantFile.toFile(), variantNode);
    }

    private static void addVersion(Path targetPath, int major, int minor, int micro, String stability, String newVersion, boolean isSpace) throws Exception {
        System.out.println("Making changes to the directory " + targetPath);
        String previousVersion = newVersion + "-SNAPSHOT";
        Path previousVersionDir = targetPath.resolve(previousVersion);
        if (!Files.exists(previousVersionDir)) {
            throw new Exception("No " + previousVersion + " WildFly version directory found for " + newVersion);
        }
        System.out.println("Previous version " + previousVersion);
        createNewVersionDirectory(previousVersion, newVersion, targetPath, true, isSpace);
        int nextMajor;
        int nextMicro;
        int previousMajor;
        String nextVersion;
        String previousMicroSnapshotVersion = null;
        String nextMicroSnapshot;
        Path nextSnapshotDir;
        Path versionsFile = targetPath.resolve("versions.yaml");
        Yaml yaml = new Yaml();
        Map<String, String> versions;
        try (FileInputStream stream = new FileInputStream(versionsFile.toFile())) {
            versions = yaml.load(stream);
        }
        String currentLatestVersion = versions.get("latest");
        Set<String> allVersions = new TreeSet<>();
        for (String v : Arrays.asList(versions.get("versions").split(","))) {
            allVersions.add(v.trim());
        }
        if (micro == 0) {
            if (stability.equals("Final")) {
                nextMajor = major + 1;
                nextVersion = nextMajor + ".0.0.Beta1";
                //Must delete the latest previous Major micro SNAPSHOT
                previousMajor = major - 1;
                Path microSnapshotDir = findDirectory(targetPath, previousMajor + "\\.0\\.*.-SNAPSHOT");
                if (microSnapshotDir != null) {
                    previousMicroSnapshotVersion = microSnapshotDir.getFileName().toString();
                }
                System.out.println("previousMicroSnapshotVersion=" + previousMicroSnapshotVersion);
                nextMicroSnapshot = major + "." + minor + ".1." + stability + "-SNAPSHOT";
                System.out.println("Creating the next micro SNAPSHOT release " + targetPath + "/" + nextMicroSnapshot);
                createNewVersionDirectory(newVersion, nextMicroSnapshot, targetPath, false, isSpace);
                allVersions.add(nextMicroSnapshot);
            } else {
                if (stability.contains("Beta")) {
                    nextVersion = major + "." + minor + "." + micro + ".Final";
                } else {
                    throw new Exception("Unknown kind of version " + newVersion);
                }
            }
            // Create the new SNAPSHOT if it doesn't already exist
            nextSnapshotDir = targetPath.resolve(nextVersion + "-SNAPSHOT");
            if (!Files.exists(nextSnapshotDir)) {
                nextVersion = nextVersion + "-SNAPSHOT";
                createNewVersionDirectory(newVersion, nextVersion, targetPath, false, isSpace);
            } else {
                System.out.println("New SNAPSHOT version " + nextVersion + "-SNAPSHOT already exists.");
                nextVersion = null;
            }
        } else {
            nextMicro = micro + 1;
            nextVersion = major + "." + minor + "." + nextMicro + "." + stability;
            nextSnapshotDir = targetPath.resolve(nextVersion + "-SNAPSHOT");
            // Create the new SNAPSHOT if it doesn't already exist
            if (!Files.exists(nextSnapshotDir)) {
                nextVersion = nextVersion + "-SNAPSHOT";
                createNewVersionDirectory(newVersion, nextVersion, targetPath, false, isSpace);
            } else {
                System.out.println("New SNAPSHOT version " + nextSnapshotDir.getFileName() + " already exists.");
                nextVersion = null;
            }
        }
        System.out.println("Deleting " + previousVersionDir + " directory");
        IoUtils.recursiveDelete(previousVersionDir);
        if (previousMicroSnapshotVersion != null) {
            Path d = targetPath.resolve(previousMicroSnapshotVersion);
            System.out.println("Deleting " + d + ", directory");
            IoUtils.recursiveDelete(d);
        }
        if (stability.equals("Final") && !isSpace) {
            // update latest
            currentLatestVersion = newVersion;
        }
        allVersions.add(newVersion);
        // Remove the current snapshot and add the new snapshot only if a new snapshot has been created
        if (nextVersion != null) {
            System.out.println("Removing " + previousVersion + " version");
            allVersions.remove(previousVersion);
            allVersions.add(nextVersion);
        }
        if (previousMicroSnapshotVersion != null) {
            System.out.println("Removing " + previousMicroSnapshotVersion + " version");
            allVersions.remove(previousMicroSnapshotVersion);
        }
        Yaml exportVersions = new Yaml();
        Map<String, String> data = new HashMap<>();
        if (currentLatestVersion != null) {
            data.put("latest", currentLatestVersion);
        }
        StringBuilder builder = new StringBuilder();
        for (String v : allVersions) {
            builder.append(v).append(",");
        }
        data.put("versions", builder.toString().substring(0, builder.length() - 1));
        FileWriter writer = new FileWriter(versionsFile.toFile());
        exportVersions.dump(data, writer);
    }

    private static Path findDirectory(Path dir, String regex) throws IOException {
        Pattern pattern = Pattern.compile(regex);
        try (Stream<Path> stream = Files.list(dir)) {
            List<Path> lst = stream
                    .filter(file -> Files.isDirectory(file))
                    .filter(file -> {
                        Matcher matcher = pattern.matcher(file.getFileName().toString());
                        return matcher.matches();
                    })
                    .collect(Collectors.toList());
            return lst.isEmpty() ? null : lst.get(0);
        }
    }

    private static void createNewVersionDirectory(String previousVersion,
            String newVersion, Path targetPath, boolean addToCatalog, boolean isSpace) throws Exception {
        Path previousVersionDir = targetPath.resolve(previousVersion);
        Path newVersionDir = targetPath.resolve(newVersion);

        System.out.println("Creating directory " + newVersionDir + " from previous version " + previousVersion);
        IoUtils.copy(previousVersionDir, newVersionDir);
        if (!isSpace) {
            List<Path> files = getAllProvisioningFiles(newVersionDir);
            for (Path f : files) {
                ProvisioningConfig.Builder builder = ProvisioningConfig.builder();
                ProvisioningConfig cfg = ProvisioningXmlParser.parse(f);
                for (FeaturePackConfig c : cfg.getFeaturePackDeps()) {
                    FeaturePackLocation loc = c.getLocation();
                    if (c.getLocation().getBuild().equals(previousVersion)) {
                        loc = c.getLocation().replaceBuild(newVersion);
                    }
                    builder.addFeaturePackDep(loc);
                }
                for (Entry<String, String> entry : cfg.getOptions().entrySet()) {
                    builder.addOption(entry.getKey(), entry.getValue());
                }
                ProvisioningXmlWriter.getInstance().write(builder.build(), f);
            }
        }
        if (addToCatalog) {
            addFeaturePacks(newVersionDir);
        }
    }

    static List<Path> getAllProvisioningFiles(Path dir) throws Exception {
        try (Stream<Path> stream = Files.walk(dir)) {
            return stream.filter(Files::isRegularFile).
                    filter(file -> file.getFileName().toString().startsWith("provisioning-")).
                    collect(Collectors.toList());
        }
    }

    private static void addFeaturePacks(Path newVersionDir) throws Exception {
        // Retrieve the files for the default variant
        addFeaturePacks("default", newVersionDir);
        try (Stream<Path> stream = Files.list(newVersionDir)) {
            List<Path> lst = stream
                    .filter(file -> Files.isDirectory(file))
                    .collect(Collectors.toList());
            for (Path p : lst) {
                addFeaturePacks(p.getFileName().toString(), p);
            }
        }
    }

    private static void addFeaturePacks(String variant, Path dir) throws Exception {
        try (Stream<Path> stream = Files.list(dir)) {
            List<Path> files = stream
                    .filter(file -> !Files.isDirectory(file))
                    .filter(file -> file.getFileName().toString().startsWith("provisioning-"))
                    .collect(Collectors.toList());
            Set<String> fps = KNOWN_FEATURE_PACKS.get(variant);
            if (fps == null) {
                fps = new LinkedHashSet<>();
                KNOWN_FEATURE_PACKS.put(variant, fps);
            }
            for (Path p : files) {
                ProvisioningConfig cfg = ProvisioningXmlParser.parse(p);
                for (FeaturePackConfig c : cfg.getFeaturePackDeps()) {
                    fps.add(c.getLocation().toString());
                }
            }
        }
    }
}
