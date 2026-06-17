<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dcx="https://dfm.dk"
    exclude-result-prefixes="dcx">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

    <!-- Group table-item subelements by local-name within supported list sections. -->
    <xsl:key name="kExtraField"
         match="dcx:equipmentList/dcx:equipment/*
           | dcx:statementList/dcx:statement/*
           | dcx:settingList/dcx:setting/*
           | dcx:measurementConfigList/dcx:measurementConfig/*"
         use="concat(generate-id(ancestor::*[self::dcx:equipmentList or self::dcx:statementList or self::dcx:settingList or self::dcx:measurementConfigList][1]), '|', local-name())"/>

    <!-- Group table-item attributes by local-name within supported list sections. -->
    <xsl:key name="kExtraAttribute"
       match="dcx:equipmentList/dcx:equipment/@*
         | dcx:statementList/dcx:statement/@*
         | dcx:settingList/dcx:setting/@*
         | dcx:measurementConfigList/dcx:measurementConfig/@*"
         use="concat(generate-id(ancestor::*[self::dcx:equipmentList or self::dcx:statementList or self::dcx:settingList or self::dcx:measurementConfigList][1]), '|', local-name())"/>

  <!-- Step 1 default language is English. -->
  <xsl:param name="defaultLang" select="'en'"/>

  <!-- Select text by language with fallback to first available node or fallback text. -->
  <xsl:template name="label-by-lang">
    <xsl:param name="nodes"/>
    <xsl:param name="fallback" select="''"/>
    <xsl:choose>
      <xsl:when test="$nodes[@lang = $defaultLang]">
        <xsl:value-of select="$nodes[@lang = $defaultLang][1]"/>
      </xsl:when>
      <xsl:when test="$nodes">
        <xsl:value-of select="$nodes[1]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$fallback"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Render a single token: link it when it matches an existing @id, else plain text. -->
  <xsl:template name="render-linked-token">
    <xsl:param name="token"/>
    <xsl:choose>
        <xsl:when test="normalize-space($token) and /dcx:digitalCalibrationExchange//*[@id = normalize-space($token) or @tableId = normalize-space($token)]">
        <a>
          <xsl:attribute name="href">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="normalize-space($token)"/>
          </xsl:attribute>
          <xsl:value-of select="normalize-space($token)"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space($token)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Recursively render a space-separated list of tokens (IDREFS), linking each one. -->
  <xsl:template name="render-linked-tokens">
    <xsl:param name="text"/>
    <xsl:variable name="trimmed" select="normalize-space($text)"/>
    <xsl:choose>
      <xsl:when test="contains($trimmed, ' ')">
        <xsl:call-template name="render-linked-token">
          <xsl:with-param name="token" select="substring-before($trimmed, ' ')"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:call-template name="render-linked-tokens">
          <xsl:with-param name="text" select="substring-after($trimmed, ' ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="normalize-space($trimmed)">
        <xsl:call-template name="render-linked-token">
          <xsl:with-param name="token" select="$trimmed"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Render plain text or an in-document link. Multi-token (IDREFS) values are split and each token linked. -->
  <xsl:template name="render-linked-value">
    <xsl:param name="value"/>
    <xsl:call-template name="render-linked-tokens">
      <xsl:with-param name="text" select="$value"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Render a node value, using @value when simple-content text is empty. -->
  <xsl:template name="render-linked-node">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node and normalize-space($node)">
        <xsl:call-template name="render-linked-value">
          <xsl:with-param name="value" select="$node"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$node and normalize-space($node/@value)">
        <xsl:call-template name="render-linked-value">
          <xsl:with-param name="value" select="$node/@value"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Canonical list container id for key scoping across all supported sections. -->
  <xsl:template name="list-id">
    <xsl:param name="node"/>
    <xsl:value-of select="generate-id($node/ancestor-or-self::*[self::dcx:equipmentList or self::dcx:statementList or self::dcx:settingList or self::dcx:measurementConfigList][1])"/>
  </xsl:template>

  <xsl:template name="render-embedded-image">
    <xsl:param name="file"/>
    <xsl:param name="alt" select="''"/>
    <xsl:variable name="ext" select="translate(normalize-space($file/dcx:fileExtension), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
    <xsl:variable name="mime">
      <xsl:choose>
        <xsl:when test="$ext = 'png'">image/png</xsl:when>
        <xsl:when test="$ext = 'jpg' or $ext = 'jpeg'">image/jpeg</xsl:when>
        <xsl:when test="$ext = 'gif'">image/gif</xsl:when>
        <xsl:when test="$ext = 'webp'">image/webp</xsl:when>
        <xsl:when test="$ext = 'svg' or $ext = 'svg+xml'">image/svg+xml</xsl:when>
        <xsl:when test="$ext = 'bmp'">image/bmp</xsl:when>
        <xsl:when test="$ext = 'tif' or $ext = 'tiff'">image/tiff</xsl:when>
        <xsl:otherwise>application/octet-stream</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <img class="embedded-image">
      <xsl:attribute name="src">
        <xsl:value-of select="concat('data:', $mime, ';base64,', normalize-space($file/dcx:fileContent))"/>
      </xsl:attribute>
      <xsl:attribute name="alt">
        <xsl:value-of select="$alt"/>
      </xsl:attribute>
    </img>
  </xsl:template>

  <xsl:template name="render-image-ref-token">
    <xsl:param name="token"/>
    <xsl:variable name="trimmed" select="normalize-space($token)"/>
    <xsl:variable name="file" select="/dcx:digitalCalibrationExchange/dcx:embeddedFileList/dcx:embeddedFile[@id = $trimmed][1]"/>
    <xsl:variable name="ext" select="translate(normalize-space($file/dcx:fileExtension), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
    <xsl:choose>
      <xsl:when test="$file and normalize-space($file/dcx:fileContent) and ($ext = 'png' or $ext = 'jpg' or $ext = 'jpeg' or $ext = 'gif' or $ext = 'webp' or $ext = 'svg' or $ext = 'svg+xml' or $ext = 'bmp' or $ext = 'tif' or $ext = 'tiff')">
        <xsl:call-template name="render-embedded-image">
          <xsl:with-param name="file" select="$file"/>
          <xsl:with-param name="alt" select="$trimmed"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$file and normalize-space($file/dcx:fileContent)">
        <xsl:value-of select="$file/dcx:fileContent"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$trimmed"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="render-image-ref-values">
    <xsl:param name="text"/>
    <xsl:variable name="trimmed" select="normalize-space($text)"/>
    <xsl:choose>
      <xsl:when test="contains($trimmed, ' ')">
        <xsl:call-template name="render-image-ref-token">
          <xsl:with-param name="token" select="substring-before($trimmed, ' ')"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:call-template name="render-image-ref-values">
          <xsl:with-param name="text" select="substring-after($trimmed, ' ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="normalize-space($trimmed)">
        <xsl:call-template name="render-image-ref-token">
          <xsl:with-param name="token" select="$trimmed"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="render-service-provider">
    <xsl:param name="provider"/>
    <xsl:if test="$provider">
      <div class="provider-block">
        <div class="provider-label">
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="$provider/dcx:heading"/>
            <xsl:with-param name="fallback" select="'Service provider'"/>
          </xsl:call-template>
        </div>
        <xsl:if test="normalize-space($provider/dcx:name)">
          <div class="provider-name">
            <xsl:value-of select="$provider/dcx:name"/>
          </div>
        </xsl:if>
        <xsl:if test="$provider/dcx:address">
          <div class="provider-line">
            <xsl:value-of select="$provider/dcx:address/dcx:street"/>
            <xsl:if test="normalize-space($provider/dcx:address/dcx:streetNo)">
              <xsl:text> </xsl:text>
              <xsl:value-of select="$provider/dcx:address/dcx:streetNo"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:address/dcx:postalCode) or normalize-space($provider/dcx:address/dcx:city)">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$provider/dcx:address/dcx:postalCode"/>
              <xsl:if test="normalize-space($provider/dcx:address/dcx:postalCode) and normalize-space($provider/dcx:address/dcx:city)">
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:value-of select="$provider/dcx:address/dcx:city"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:address/dcx:country)">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$provider/dcx:address/dcx:country"/>
            </xsl:if>
          </div>
        </xsl:if>
        <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:attPerson) or normalize-space($provider/dcx:contactInfo/dcx:email) or normalize-space($provider/dcx:contactInfo/dcx:phone) or normalize-space($provider/dcx:contactInfo/dcx:mobile) or normalize-space($provider/dcx:contactInfo/dcx:fax)">
          <div class="provider-line">
            <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:attPerson)">
              <xsl:value-of select="$provider/dcx:contactInfo/dcx:attPerson"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:email)">
              <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:attPerson)">
                <xsl:text>; </xsl:text>
              </xsl:if>
              <xsl:value-of select="$provider/dcx:contactInfo/dcx:email"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:phone)">
              <xsl:text>; </xsl:text>
              <xsl:value-of select="$provider/dcx:contactInfo/dcx:phone"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:mobile)">
              <xsl:text>; </xsl:text>
              <xsl:value-of select="$provider/dcx:contactInfo/dcx:mobile"/>
            </xsl:if>
            <xsl:if test="normalize-space($provider/dcx:contactInfo/dcx:fax)">
              <xsl:text>; </xsl:text>
              <xsl:value-of select="$provider/dcx:contactInfo/dcx:fax"/>
            </xsl:if>
          </div>
        </xsl:if>
        <xsl:if test="normalize-space($provider/@imageRefs)">
          <div class="provider-line">
            <xsl:call-template name="render-image-ref-values">
              <xsl:with-param name="text" select="$provider/@imageRefs"/>
            </xsl:call-template>
          </div>
        </xsl:if>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-accreditation">
    <xsl:param name="acc"/>
    <xsl:if test="$acc">
      <div class="accreditation-block">
        <div class="accreditation-label">
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="$acc/dcx:heading"/>
            <xsl:with-param name="fallback" select="'Accreditation'"/>
          </xsl:call-template>
        </div>
        <xsl:for-each select="$acc/*[not(self::dcx:heading)]">
          <div class="accreditation-line">
            <span class="accreditation-key">
              <xsl:choose>
                <xsl:when test="@value and dcx:heading">
                  <xsl:call-template name="label-by-lang">
                    <xsl:with-param name="nodes" select="dcx:heading"/>
                    <xsl:with-param name="fallback" select="local-name()"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>: </xsl:text>
            </span>
            <xsl:choose>
              <xsl:when test="@value">
                <xsl:call-template name="render-linked-value">
                  <xsl:with-param name="value" select="@value"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="render-linked-node">
                  <xsl:with-param name="node" select="."/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </div>
        </xsl:for-each>
        <xsl:if test="normalize-space($acc/@statementRef)">
          <div class="accreditation-line">
            <span class="accreditation-key">statementRef: </span>
            <xsl:call-template name="render-linked-value">
              <xsl:with-param name="value" select="$acc/@statementRef"/>
            </xsl:call-template>
          </div>
        </xsl:if>
        <xsl:if test="normalize-space($acc/@imageRefs)">
          <div class="accreditation-line">
            <xsl:call-template name="render-image-ref-values">
              <xsl:with-param name="text" select="$acc/@imageRefs"/>
            </xsl:call-template>
          </div>
        </xsl:if>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-core-data">
    <xsl:param name="core"/>
    <xsl:if test="$core">
      <div class="coredata-block">
        <xsl:for-each select="$core/*">
          <div class="coredata-line">
            <span class="coredata-key">
              <xsl:choose>
                <xsl:when test="dcx:heading">
                  <xsl:call-template name="label-by-lang">
                    <xsl:with-param name="nodes" select="dcx:heading"/>
                    <xsl:with-param name="fallback" select="local-name()"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>: </xsl:text>
            </span>
            <xsl:choose>
              <xsl:when test="@value">
                <xsl:call-template name="render-linked-value">
                  <xsl:with-param name="value" select="@value"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="render-linked-node">
                  <xsl:with-param name="node" select="."/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-document-authorization">
    <xsl:param name="docAuth"/>
    <xsl:if test="$docAuth">
      <div class="coredata-block">
        <div class="coredata-section-label">
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="$docAuth/dcx:heading"/>
            <xsl:with-param name="fallback" select="'Document authorisation'"/>
          </xsl:call-template>
        </div>
        <xsl:for-each select="$docAuth/*[not(self::dcx:heading)]">
          <div class="coredata-person-block">
            <xsl:if test="dcx:heading">
              <div class="coredata-person-heading">
                <xsl:call-template name="label-by-lang">
                  <xsl:with-param name="nodes" select="dcx:heading"/>
                  <xsl:with-param name="fallback" select="local-name()"/>
                </xsl:call-template>
              </div>
            </xsl:if>
            <xsl:if test="dcx:name">
              <div class="coredata-line">
                <xsl:choose>
                  <xsl:when test="normalize-space(dcx:name[1]/@value)">
                    <xsl:call-template name="render-linked-value">
                      <xsl:with-param name="value" select="dcx:name[1]/@value"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="render-linked-node">
                      <xsl:with-param name="node" select="dcx:name[1]"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </div>
            </xsl:if>
            <xsl:if test="dcx:email">
              <div class="coredata-line">
                <xsl:choose>
                  <xsl:when test="normalize-space(dcx:email[1]/@value)">
                    <xsl:call-template name="render-linked-value">
                      <xsl:with-param name="value" select="dcx:email[1]/@value"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="render-linked-node">
                      <xsl:with-param name="node" select="dcx:email[1]"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </div>
            </xsl:if>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-contact-value-line">
    <xsl:param name="cols"/>
    <xsl:param name="colName"/>
    <xsl:param name="value"/>
    <xsl:param name="isImageRefs" select="'no'"/>
    <xsl:if test="normalize-space($value)">
      <div class="contact-line">
        <xsl:variable name="label">
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="$cols/dcx:column[@name = $colName]/dcx:heading"/>
            <xsl:with-param name="fallback" select="''"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="normalize-space($label)">
          <span class="contact-key">
            <xsl:value-of select="$label"/>
            <xsl:text>: </xsl:text>
          </span>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$isImageRefs = 'yes'">
            <xsl:call-template name="render-image-ref-values">
              <xsl:with-param name="text" select="$value"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="render-linked-value">
              <xsl:with-param name="value" select="$value"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-contact-node">
    <xsl:param name="node"/>
    <xsl:param name="cols"/>
    <xsl:if test="$node">
      <div class="contact-block">
        <xsl:if test="$node/dcx:heading">
          <div class="contact-title">
            <xsl:call-template name="label-by-lang">
              <xsl:with-param name="nodes" select="$node/dcx:heading"/>
              <xsl:with-param name="fallback" select="''"/>
            </xsl:call-template>
          </div>
        </xsl:if>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'@id'"/>
          <xsl:with-param name="value" select="$node/@id"/>
        </xsl:call-template>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'@imageRefs'"/>
          <xsl:with-param name="value" select="$node/@imageRefs"/>
          <xsl:with-param name="isImageRefs" select="'yes'"/>
        </xsl:call-template>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'name'"/>
          <xsl:with-param name="value" select="$node/dcx:name[1]"/>
        </xsl:call-template>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'VATIN'"/>
          <xsl:with-param name="value" select="$node/dcx:VATIN[1]"/>
        </xsl:call-template>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'url'"/>
          <xsl:with-param name="value" select="$node/dcx:url[1]"/>
        </xsl:call-template>

        <xsl:variable name="addressLine">
          <xsl:value-of select="$node/dcx:address/dcx:street"/>
          <xsl:if test="normalize-space($node/dcx:address/dcx:streetNo)">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:streetNo"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:address/dcx:postOfficeBox)">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:postOfficeBox"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:address/dcx:postalCode) or normalize-space($node/dcx:address/dcx:city)">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:postalCode"/>
            <xsl:if test="normalize-space($node/dcx:address/dcx:postalCode) and normalize-space($node/dcx:address/dcx:city)">
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="$node/dcx:address/dcx:city"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:address/dcx:district)">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:district"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:address/dcx:state)">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:state"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:address/dcx:country)">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$node/dcx:address/dcx:country"/>
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="contactInfoLine">
          <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:attPerson)">
            <xsl:value-of select="$node/dcx:contactInfo/dcx:attPerson"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:email)">
            <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:attPerson)">
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:value-of select="$node/dcx:contactInfo/dcx:email"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:mobile)">
            <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:attPerson) or normalize-space($node/dcx:contactInfo/dcx:email)">
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:value-of select="$node/dcx:contactInfo/dcx:mobile"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:phone)">
            <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:attPerson) or normalize-space($node/dcx:contactInfo/dcx:email) or normalize-space($node/dcx:contactInfo/dcx:mobile)">
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:value-of select="$node/dcx:contactInfo/dcx:phone"/>
          </xsl:if>
          <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:fax)">
            <xsl:if test="normalize-space($node/dcx:contactInfo/dcx:attPerson) or normalize-space($node/dcx:contactInfo/dcx:email) or normalize-space($node/dcx:contactInfo/dcx:mobile) or normalize-space($node/dcx:contactInfo/dcx:phone)">
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:value-of select="$node/dcx:contactInfo/dcx:fax"/>
          </xsl:if>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="self::dcx:location">
            <div class="location-card">
              <div class="location-col">
                <xsl:call-template name="render-contact-value-line">
                  <xsl:with-param name="cols" select="$cols"/>
                  <xsl:with-param name="colName" select="'address'"/>
                  <xsl:with-param name="value" select="$addressLine"/>
                </xsl:call-template>
              </div>
              <div class="location-col">
                <xsl:call-template name="render-contact-value-line">
                  <xsl:with-param name="cols" select="$cols"/>
                  <xsl:with-param name="colName" select="'contactInfo'"/>
                  <xsl:with-param name="value" select="$contactInfoLine"/>
                </xsl:call-template>
              </div>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="render-contact-value-line">
              <xsl:with-param name="cols" select="$cols"/>
              <xsl:with-param name="colName" select="'address'"/>
              <xsl:with-param name="value" select="$addressLine"/>
            </xsl:call-template>
            <xsl:call-template name="render-contact-value-line">
              <xsl:with-param name="cols" select="$cols"/>
              <xsl:with-param name="colName" select="'contactInfo'"/>
              <xsl:with-param name="value" select="$contactInfoLine"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="render-contact-value-line">
          <xsl:with-param name="cols" select="$cols"/>
          <xsl:with-param name="colName" select="'onsiteDirections'"/>
          <xsl:with-param name="value" select="$node/dcx:onsiteDirections"/>
        </xsl:call-template>

        <xsl:if test="$node/dcx:geoPosition">
          <xsl:variable name="geoLine">
            <xsl:value-of select="$node/dcx:geoPosition/dcx:longitude"/>
            <xsl:if test="normalize-space($node/dcx:geoPosition/dcx:latitude)">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$node/dcx:geoPosition/dcx:latitude"/>
            </xsl:if>
            <xsl:if test="normalize-space($node/dcx:geoPosition/dcx:altitude)">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$node/dcx:geoPosition/dcx:altitude"/>
            </xsl:if>
          </xsl:variable>
          <xsl:call-template name="render-contact-value-line">
            <xsl:with-param name="cols" select="$cols"/>
            <xsl:with-param name="colName" select="'geoPosition'"/>
            <xsl:with-param name="value" select="$geoLine"/>
          </xsl:call-template>
        </xsl:if>

        <xsl:for-each select="$node/dcx:body">
          <xsl:call-template name="render-contact-value-line">
            <xsl:with-param name="cols" select="$cols"/>
            <xsl:with-param name="colName" select="'body'"/>
            <xsl:with-param name="value" select="."/>
          </xsl:call-template>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="render-contact-elements">
    <xsl:param name="admin"/>
    <xsl:if test="$admin">
      <xsl:variable name="cols" select="$admin/dcx:contactColumnHeadings"/>
      <div class="contact-list-block">
        <xsl:for-each select="$admin/*[self::dcx:client or self::dcx:serviceProvider or self::dcx:clientBillingInfo or self::dcx:equipmentReturnInfo or self::dcx:certificateReturnInfo or self::dcx:location]">
          <xsl:call-template name="render-contact-node">
            <xsl:with-param name="node" select="."/>
            <xsl:with-param name="cols" select="$cols"/>
          </xsl:call-template>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/">
    <html>
      <head>
        <title>
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="/dcx:digitalCalibrationExchange/dcx:title/dcx:heading"/>
            <xsl:with-param name="fallback" select="'Calibration Certificate'"/>
          </xsl:call-template>
        </title>
        <style type="text/css">
          body { font-family: Arial, Helvetica, sans-serif; margin: 1.2rem; color: #222; }
          .header-grid { display: table; width: 100%; margin: 0 0 1rem 0; table-layout: fixed; }
          .header-col { display: table-cell; vertical-align: top; width: 50%; }
          .header-col.left { padding-right: 0.45rem; }
          .header-col.right { padding-left: 0.45rem; text-align: right; }
          .provider-block { margin: 0 0 1rem 0; padding: 0.7rem 0.9rem; border: 0; background: transparent; }
          .provider-label { margin-bottom: 0.25rem; font-size: 0.85rem; font-weight: 700; text-transform: uppercase; color: #666; }
          .provider-name { font-size: 1.05rem; font-weight: 700; }
          .provider-line { margin-top: 0.15rem; color: #444; }
          .accreditation-block { margin: 0 0 1rem 0; padding: 0.7rem 0.9rem; border: 0; background: transparent; display: inline-block; text-align: left; }
          .accreditation-label { margin-bottom: 0.25rem; font-size: 0.85rem; font-weight: 700; text-transform: uppercase; color: #666; }
          .accreditation-line { margin-top: 0.15rem; color: #444; }
          .accreditation-key { font-weight: 700; color: #555; }
          .coredata-block { margin: 0 0 0.8rem 0; }
          .coredata-section-label { margin: 0 0 0.2rem 0; font-size: 0.95rem; font-weight: 700; color: #333; }
          .coredata-person-block { margin: 0 0 0.4rem 0; }
          .coredata-person-heading { margin-top: 0.12rem; font-weight: 700; color: #555; }
          .coredata-line { margin-top: 0.12rem; color: #444; }
          .coredata-key { font-weight: 700; color: #555; }
          .contact-list-block { margin: 0 0 0.8rem 0; }
          .contact-block { margin: 0 0 0.55rem 0; }
          .contact-title { margin-top: 0.15rem; font-weight: 700; color: #333; }
          .location-card { display: table; width: 100%; table-layout: fixed; margin-top: 0.12rem; }
          .location-col { display: table-cell; width: 50%; vertical-align: top; padding-right: 0.45rem; }
          .location-col + .location-col { padding-right: 0; padding-left: 0.45rem; }
          .contact-line { margin-top: 0.12rem; color: #444; }
          .contact-key { font-weight: 700; color: #555; }
          .embedded-image { max-height: 100px; max-width: 320px; border: 0; padding: 0; background: transparent; }
          h1 { margin: 0 0 0.25rem 0; font-size: 1.8rem; }
          h2 { margin: 0 0 1rem 0; font-size: 1.1rem; font-weight: 500; color: #555; }
          .section { margin-top: 1.4rem; }
          .section-title { margin: 0 0 0.55rem 0; font-size: 1.15rem; }
          .table-title { margin: 1rem 0 0.2rem 0; font-size: 1.05rem; }
          .table-subtitle { margin: 0 0 0.55rem 0; font-size: 0.9rem; color: #555; }
          .col-meta { display: block; margin-top: 0.2rem; font-size: 0.78rem; color: #666; font-weight: normal; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #cfcfcf; padding: 0.35rem 0.45rem; text-align: left; vertical-align: top; }
          th { background: #f4f4f4; }
          .empty { color: #888; }
        </style>
      </head>
      <body>
        <!-- Global anchor targets for all IDs and tableIds to support in-document links. -->
        <div style="display:none">
          <xsl:for-each select="/dcx:digitalCalibrationExchange//*[@id or @tableId]">
            <span>
              <xsl:attribute name="id">
                <xsl:choose>
                  <xsl:when test="@id">
                    <xsl:value-of select="@id"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="@tableId"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </span>
          </xsl:for-each>
        </div>

        <div class="header-grid">
          <div class="header-col left">
            <xsl:call-template name="render-service-provider">
              <xsl:with-param name="provider" select="/dcx:digitalCalibrationExchange/dcx:administrativeData/dcx:serviceProvider[1]"/>
            </xsl:call-template>
          </div>
          <div class="header-col right">
            <xsl:call-template name="render-accreditation">
              <xsl:with-param name="acc" select="/dcx:digitalCalibrationExchange/dcx:administrativeData/dcx:accreditation[1]"/>
            </xsl:call-template>
          </div>
        </div>

        <h1>
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="/dcx:digitalCalibrationExchange/dcx:title/dcx:heading"/>
            <xsl:with-param name="fallback" select="'Calibration Certificate'"/>
          </xsl:call-template>
        </h1>

        <xsl:call-template name="render-core-data">
          <xsl:with-param name="core" select="/dcx:digitalCalibrationExchange/dcx:administrativeData/dcx:coreData[1]"/>
        </xsl:call-template>

        <xsl:call-template name="render-document-authorization">
          <xsl:with-param name="docAuth" select="/dcx:digitalCalibrationExchange/dcx:administrativeData/dcx:documentAuthorization[1]"/>
        </xsl:call-template>

        <xsl:call-template name="render-contact-elements">
          <xsl:with-param name="admin" select="/dcx:digitalCalibrationExchange/dcx:administrativeData[1]"/>
        </xsl:call-template>

        <xsl:if test="/dcx:digitalCalibrationExchange/dcx:subtitle">
          <h2>
            <xsl:call-template name="label-by-lang">
              <xsl:with-param name="nodes" select="/dcx:digitalCalibrationExchange/dcx:subtitle[1]/dcx:heading"/>
              <xsl:with-param name="fallback" select="''"/>
            </xsl:call-template>
          </h2>
        </xsl:if>

        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:equipmentList"/>
        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:statementList"/>
        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:settingList"/>
        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:measurementConfigList"/>
        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:measurementResultList"/>
        <xsl:apply-templates select="/dcx:digitalCalibrationExchange/dcx:embeddedFileList"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="dcx:equipmentList">
    <xsl:call-template name="render-list-table">
      <xsl:with-param name="listNode" select="."/>
      <xsl:with-param name="itemNodes" select="dcx:equipment"/>
      <xsl:with-param name="fallbackTitle" select="'Equipment'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dcx:statementList">
    <xsl:call-template name="render-list-table">
      <xsl:with-param name="listNode" select="."/>
      <xsl:with-param name="itemNodes" select="dcx:statement"/>
      <xsl:with-param name="fallbackTitle" select="'Statements'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dcx:settingList">
    <xsl:call-template name="render-list-table">
      <xsl:with-param name="listNode" select="."/>
      <xsl:with-param name="itemNodes" select="dcx:setting"/>
      <xsl:with-param name="fallbackTitle" select="'Settings'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dcx:measurementConfigList">
    <xsl:call-template name="render-list-table">
      <xsl:with-param name="listNode" select="."/>
      <xsl:with-param name="itemNodes" select="dcx:measurementConfig"/>
      <xsl:with-param name="fallbackTitle" select="'Measurement Configurations'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dcx:embeddedFileList">
    <div class="section">
      <h3 class="section-title">
        <xsl:call-template name="label-by-lang">
          <xsl:with-param name="nodes" select="dcx:heading"/>
          <xsl:with-param name="fallback" select="'Embedded Files'"/>
        </xsl:call-template>
      </h3>
      <table>
        <thead>
          <tr>
            <th>@id</th>
            <th>fileExtension</th>
            <th>content</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="dcx:embeddedFile">
            <xsl:variable name="ext" select="translate(normalize-space(dcx:fileExtension), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
            <tr>
              <xsl:if test="@id">
                <xsl:attribute name="id">
                  <xsl:value-of select="@id"/>
                </xsl:attribute>
              </xsl:if>
              <td>
                <xsl:value-of select="@id"/>
              </td>
              <td>
                <xsl:value-of select="dcx:fileExtension"/>
              </td>
              <td>
                <xsl:choose>
                  <xsl:when test="normalize-space(dcx:fileContent) and ($ext = 'png' or $ext = 'jpg' or $ext = 'jpeg' or $ext = 'gif' or $ext = 'webp' or $ext = 'svg' or $ext = 'svg+xml' or $ext = 'bmp' or $ext = 'tif' or $ext = 'tiff')">
                    <xsl:call-template name="render-embedded-image">
                      <xsl:with-param name="file" select="."/>
                      <xsl:with-param name="alt" select="@id"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="dcx:fileContent"/>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
  </xsl:template>

  <xsl:template name="render-list-table">
    <xsl:param name="listNode"/>
    <xsl:param name="itemNodes"/>
    <xsl:param name="fallbackTitle" select="'Section'"/>

    <xsl:if test="$listNode and $itemNodes">
      <xsl:variable name="listId" select="generate-id($listNode)"/>

    <div class="section">
      <h3 class="section-title">
        <xsl:call-template name="label-by-lang">
          <xsl:with-param name="nodes" select="$listNode/dcx:heading"/>
          <xsl:with-param name="fallback" select="$fallbackTitle"/>
        </xsl:call-template>
      </h3>

      <table>
        <thead>
          <tr>
            <xsl:for-each select="$listNode/dcx:columnHeadings/dcx:column">
              <th>
                <xsl:call-template name="label-by-lang">
                  <xsl:with-param name="nodes" select="dcx:heading"/>
                  <xsl:with-param name="fallback" select="@name"/>
                </xsl:call-template>
              </th>
            </xsl:for-each>
            <xsl:for-each select="$itemNodes/@*[normalize-space(.)
                                      and not(concat('@', local-name()) = $listNode/dcx:columnHeadings/dcx:column/@name)
                                      and generate-id() = generate-id(key('kExtraAttribute', concat($listId, '|', local-name()))[1])]">
              <th>
                <xsl:text>@</xsl:text>
                <xsl:value-of select="local-name()"/>
              </th>
            </xsl:for-each>
            <xsl:for-each select="$itemNodes/*[not(local-name() = $listNode/dcx:columnHeadings/dcx:column/@name)
                                      and generate-id() = generate-id(key('kExtraField', concat($listId, '|', local-name()))[1])]">
              <th>
                <xsl:text>dcx:</xsl:text>
                <xsl:value-of select="local-name()"/>
              </th>
            </xsl:for-each>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="$itemNodes">
            <xsl:variable name="row" select="."/>
            <tr>
              <xsl:if test="$row/@id">
                <xsl:attribute name="id">
                  <xsl:value-of select="$row/@id"/>
                </xsl:attribute>
              </xsl:if>
              <xsl:for-each select="$listNode/dcx:columnHeadings/dcx:column">
                <xsl:variable name="colName" select="@name"/>
                <td>
                  <xsl:choose>
                    <xsl:when test="starts-with($colName, '@')">
                      <xsl:call-template name="render-linked-value">
                        <xsl:with-param name="value" select="$row/@*[name() = substring($colName, 2)]"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="$colName = 'heading'">
                      <xsl:call-template name="label-by-lang">
                        <xsl:with-param name="nodes" select="$row/dcx:heading"/>
                        <xsl:with-param name="fallback" select="''"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:variable name="cellNodes" select="$row/*[local-name() = $colName]"/>
                      <xsl:choose>
                        <xsl:when test="$cellNodes[@lang]">
                          <xsl:call-template name="label-by-lang">
                            <xsl:with-param name="nodes" select="$cellNodes"/>
                            <xsl:with-param name="fallback" select="''"/>
                          </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:call-template name="render-linked-node">
                            <xsl:with-param name="node" select="$cellNodes[1]"/>
                          </xsl:call-template>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:if test="not(starts-with($colName, '@')) and not($colName = 'heading') and not(normalize-space($row/*[local-name() = $colName][1])) and not(normalize-space($row/*[local-name() = $colName][1]/@value))">
                    <span class="empty">
                      <xsl:text></xsl:text>
                    </span>
                  </xsl:if>
                </td>
              </xsl:for-each>
              <xsl:for-each select="$itemNodes/@*[normalize-space(.)
                                        and not(concat('@', local-name()) = $listNode/dcx:columnHeadings/dcx:column/@name)
                                        and generate-id() = generate-id(key('kExtraAttribute', concat($listId, '|', local-name()))[1])]">
                <xsl:variable name="attrName" select="local-name()"/>
                <td>
                  <xsl:call-template name="render-linked-value">
                    <xsl:with-param name="value" select="$row/@*[local-name() = $attrName]"/>
                  </xsl:call-template>
                  <xsl:if test="not(normalize-space($row/@*[local-name() = $attrName]))">
                    <span class="empty">
                      <xsl:text></xsl:text>
                    </span>
                  </xsl:if>
                </td>
              </xsl:for-each>
              <xsl:for-each select="$itemNodes/*[not(local-name() = $listNode/dcx:columnHeadings/dcx:column/@name)
                                        and generate-id() = generate-id(key('kExtraField', concat($listId, '|', local-name()))[1])]">
                <xsl:variable name="colName" select="local-name()"/>
                <td>
                  <xsl:variable name="cellNodes" select="$row/*[local-name() = $colName]"/>
                  <xsl:choose>
                    <xsl:when test="$cellNodes[@lang]">
                      <xsl:call-template name="label-by-lang">
                        <xsl:with-param name="nodes" select="$cellNodes"/>
                        <xsl:with-param name="fallback" select="''"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="render-linked-node">
                        <xsl:with-param name="node" select="$cellNodes[1]"/>
                      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:if test="not(normalize-space($cellNodes[1])) and not(normalize-space($cellNodes[1]/@value))">
                    <span class="empty">
                      <xsl:text></xsl:text>
                    </span>
                  </xsl:if>
                </td>
              </xsl:for-each>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="dcx:measurementResultList">
    <xsl:variable name="root" select="/dcx:digitalCalibrationExchange"/>
    <div class="section">
      <h3 class="section-title">
        <xsl:call-template name="label-by-lang">
          <xsl:with-param name="nodes" select="dcx:heading"/>
          <xsl:with-param name="fallback" select="'Measurement Results'"/>
        </xsl:call-template>
      </h3>

      <xsl:for-each select="*[ @tableId ]">
        <xsl:sort select="@tableId"/>
        <xsl:variable name="table" select="."/>
        <xsl:variable name="config" select="$root/dcx:measurementConfigList/dcx:measurementConfig[@id = $table/@measurementConfigRef][1]"/>

        <h4 class="table-title">
          <xsl:call-template name="label-by-lang">
            <xsl:with-param name="nodes" select="dcx:heading"/>
            <xsl:with-param name="fallback" select="local-name()"/>
          </xsl:call-template>
        </h4>

        <div class="table-subtitle">
          <xsl:text>tableId=</xsl:text>
          <xsl:call-template name="render-linked-value">
            <xsl:with-param name="value" select="@tableId"/>
          </xsl:call-template>
          <xsl:text>; measurementConfigRef=</xsl:text>
          <xsl:call-template name="render-linked-value">
            <xsl:with-param name="value" select="@measurementConfigRef"/>
          </xsl:call-template>
          <xsl:text>; measurementConfigHeading=</xsl:text>
          <xsl:choose>
            <xsl:when test="$config">
              <xsl:call-template name="label-by-lang">
                <xsl:with-param name="nodes" select="$config/dcx:heading"/>
                <xsl:with-param name="fallback" select="$config/@id"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text></xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </div>

        <table>
          <thead>
            <tr>
              <xsl:for-each select="dcx:column">
                <th>
                  <xsl:call-template name="label-by-lang">
                    <xsl:with-param name="nodes" select="dcx:heading"/>
                    <xsl:with-param name="fallback" select="concat('column-', position())"/>
                  </xsl:call-template>
                </th>
              </xsl:for-each>
            </tr>
            <tr>
              <xsl:for-each select="dcx:column">
                <th>
                  <span class="col-meta">
                    <xsl:text>scope=</xsl:text>
                    <xsl:value-of select="@scope"/>
                  </span>
                  <span class="col-meta">
                    <xsl:text>quantity=</xsl:text>
                    <xsl:value-of select="@quantity"/>
                  </span>
                  <span class="col-meta">
                    <xsl:text>unit=</xsl:text>
                    <xsl:value-of select="@unit"/>
                  </span>
                  <span class="col-meta">
                    <xsl:text>dataCategoryRef=</xsl:text>
                    <xsl:value-of select="@dataCategoryRef"/>
                  </span>
                  <span class="col-meta">
                    <xsl:text>dataCategory=</xsl:text>
                    <xsl:choose>
                      <xsl:when test="*[not(self::dcx:heading)][1]">
                        <xsl:text>dcx:</xsl:text>
                        <xsl:value-of select="local-name(*[not(self::dcx:heading)][1])"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text></xsl:text>
                      </xsl:otherwise>
                    </xsl:choose>
                  </span>
                </th>
              </xsl:for-each>
            </tr>
          </thead>
          <tbody>
            <xsl:choose>
              <xsl:when test="dcx:column[1]/*[not(self::dcx:heading)][1]/dcx:row">
                <xsl:for-each select="dcx:column[1]/*[not(self::dcx:heading)][1]/dcx:row">
                  <xsl:variable name="idx" select="@idx"/>
                  <tr>
                    <xsl:for-each select="../../../dcx:column">
                      <td>
                        <xsl:call-template name="render-linked-value">
                          <xsl:with-param name="value" select="*[not(self::dcx:heading)][1]/dcx:row[@idx = $idx]"/>
                        </xsl:call-template>
                        <xsl:if test="not(normalize-space(*[not(self::dcx:heading)][1]/dcx:row[@idx = $idx]))">
                          <span class="empty">
                            <xsl:text></xsl:text>
                          </span>
                        </xsl:if>
                      </td>
                    </xsl:for-each>
                  </tr>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <tr>
                  <td>
                    <span class="empty">
                      <xsl:text>No row data</xsl:text>
                    </span>
                  </td>
                </tr>
              </xsl:otherwise>
            </xsl:choose>
          </tbody>
        </table>
      </xsl:for-each>
    </div>
  </xsl:template>

</xsl:stylesheet>