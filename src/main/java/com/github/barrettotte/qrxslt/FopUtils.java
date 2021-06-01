package com.github.barrettotte.qrxslt;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.apache.fop.apps.FOPException;
import org.apache.fop.apps.FOUserAgent;
import org.apache.fop.apps.Fop;
import org.apache.fop.apps.FopFactory;
import org.apache.fop.apps.MimeConstants;

public class FopUtils {

    // use FO file to generate a PDF
    public void generatePDF(final File xsltFile, final File xmlSrc, final String outPath) 
      throws IOException, FOPException, TransformerException 
    {
        final StreamSource xmlStream = new StreamSource(xmlSrc);
        final FopFactory fopFactory = FopFactory.newInstance(new File(".").toURI());
        final FOUserAgent agent = fopFactory.newFOUserAgent();
        final OutputStream out = new FileOutputStream(outPath);

        try {
            final Fop fop = fopFactory.newFop(MimeConstants.MIME_PDF, agent, out);
            final TransformerFactory factory = TransformerFactory.newInstance();
            final Transformer transformer = factory.newTransformer(new StreamSource(xsltFile));
            transformer.transform(xmlStream, new SAXResult(fop.getDefaultHandler()));
        } finally {
            out.close();
        }
    }
    
    // generate XSL-FO (Formatting Objects) file 
    public static void generateFO(final File xsltFile, final File xmlSrc, final String outPath) 
      throws IOException, FOPException, TransformerException
    {
        final StreamSource xmlStream = new StreamSource(xmlSrc);
        final OutputStream out = new FileOutputStream(outPath);
        
        try {
            final TransformerFactory factory = TransformerFactory.newInstance();
            final Transformer transformer = factory.newTransformer(new StreamSource(xsltFile));
            transformer.transform(xmlStream, new StreamResult(out));
        } finally {
            out.close();
        }
    }
}
