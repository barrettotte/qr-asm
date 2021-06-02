package com.github.barrettotte.qrxslt;

import java.io.File;

public class RepoListGenerator {

    public static void main(String[] args) {
        // TODO: make test data XML
        // TODO: generate basic PDF w/o QR Code
        // TODO: generate basic QR code
        // TODO: hit GitHub API for live data XML

        final File xsltFile = new File("src/main/resources/xslt/repos.xslt");
        final File xmlFile = new File("src/main/resources/data/temp_data.xml");
        final String outFo = "src/main/resources/output/repos.fo";
        final String outPdf = "src/main/resources/output/repos.pdf";
            
        try {
            FopUtils.generateFO(xsltFile, xmlFile, outFo);
            FopUtils.generatePDF(xsltFile, xmlFile, outPdf);
        } catch(final Exception e) {
            e.printStackTrace();
        }
    }
}