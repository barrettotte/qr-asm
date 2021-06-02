<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:fo="http://www.w3.org/1999/XSL/Format" exclude-result-prefixes="fo">

    <!-- main -->
    <xsl:template match="github-user">
        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="A4" page-height="11in" page-width="8.5in" 
                  margin-top="0.5in" margin-bottom="0.5in" margin-left="1in" margin-right="1in">
                    <fo:region-body/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="A4">
                <fo:flow flow-name="xsl-region-body">
                    <xsl:call-template name="block-header"/>
                    <xsl:call-template name="block-repos"/>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>

    <!-- Generate fo:block GitHub user header -->
    <xsl:template name="block-header">
        <fo:block font-size="15pt" font-weight="bold" space-after="7mm" text-align="center">
            <xsl:value-of select="profile/name"/>'s Repositories
        </fo:block>
        <xsl:call-template name="block-qrcode"/>
    </xsl:template>

    <!-- Generate fo:block QR code -->
    <xsl:template name="block-qrcode">
        <fo:block font-size="10pt" text-align="center">
            https://github.com/<xsl:value-of select="profile/username"/>
        </fo:block>
        <!-- TODO: QR Code -->
    </xsl:template>

    <!-- Generate fo:block for list of repositories -->
    <xsl:template name="block-repos">
        <fo:block font-size="10pt">
            TODO: repository lists
        </fo:block>
    </xsl:template>

</xsl:stylesheet>