<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="1.9.0-Master" minimumScale="-4.65661e-10" maximumScale="1e+08" hasScaleBasedVisibilityFlag="0">
  <transparencyLevelInt>255</transparencyLevelInt>
  <renderer-v2 symbollevels="0" type="RuleRenderer">
    <rules>
      <rule scalemaxdenom="20000" description="Parcel boundaries" filter=" &quot;block&quot; &lt;> 'perimeter' or &quot;block&quot; is null" symbol="0" scalemindenom="1" label="parcels"/>
      <rule filter=" &quot;block&quot; &lt;> 'perimeter' or &quot;block&quot; is null" symbol="1" scalemindenom="20000" label="parcels"/>
      <rule filter=" &quot;block&quot; &lt;> 'acquisitionr' or &quot;block&quot; is null" symbol="2" scalemindenom="20000" label="acquisitions"/>
      <rule description="Scheme perimeters" filter=" &quot;block&quot; = 'perimeter'" symbol="3" label="perimeter"/>
    </rules>
    <symbols>
      <symbol outputUnit="MM" alpha="0.498039" type="fill" name="0">
        <layer pass="2" class="SimpleFill" locked="0">
          <prop k="color" v="255,0,0,255"/>
          <prop k="color_border" v="0,0,0,255"/>
          <prop k="offset" v="0,0"/>
          <prop k="style" v="diagonal_x"/>
          <prop k="style_border" v="solid"/>
          <prop k="width_border" v="0.3"/>
        </layer>
      </symbol>
      <symbol outputUnit="MM" alpha="1" type="fill" name="1">
        <layer pass="3" class="CentroidFill" locked="0">
          <symbol outputUnit="MM" alpha="1" type="marker" name="@1@0">
            <layer pass="0" class="SimpleMarker" locked="0">
              <prop k="angle" v="0"/>
              <prop k="color" v="170,85,0,255"/>
              <prop k="color_border" v="170,85,0,255"/>
              <prop k="name" v="rectangle"/>
              <prop k="offset" v="0,0"/>
              <prop k="scale_method" v="area"/>
              <prop k="size" v="0.1"/>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol outputUnit="MM" alpha="1" type="fill" name="2">
        <layer pass="0" class="SimpleFill" locked="0">
          <prop k="color" v="86,35,135,255"/>
          <prop k="color_border" v="170,0,127,255"/>
          <prop k="offset" v="0,0"/>
          <prop k="style" v="no"/>
          <prop k="style_border" v="dot"/>
          <prop k="width_border" v="0.26"/>
        </layer>
      </symbol>
      <symbol outputUnit="MM" alpha="1" type="fill" name="3">
        <layer pass="1" class="SimpleFill" locked="0">
          <prop k="color" v="170,0,0,255"/>
          <prop k="color_border" v="170,0,0,255"/>
          <prop k="offset" v="0,0"/>
          <prop k="style" v="no"/>
          <prop k="style_border" v="dash"/>
          <prop k="width_border" v="0.26"/>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <customproperties>
    <property key="labeling" value="pal"/>
    <property key="labeling/addDirectionSymbol" value="false"/>
    <property key="labeling/angleOffset" value="0"/>
    <property key="labeling/bufferColorB" value="255"/>
    <property key="labeling/bufferColorG" value="255"/>
    <property key="labeling/bufferColorR" value="255"/>
    <property key="labeling/bufferJoinStyle" value="64"/>
    <property key="labeling/bufferNoFill" value="false"/>
    <property key="labeling/bufferSize" value="0.1"/>
    <property key="labeling/bufferSizeInMapUnits" value="true"/>
    <property key="labeling/bufferTransp" value="0"/>
    <property key="labeling/centroidWhole" value="false"/>
    <property key="labeling/dataDefined/AlwaysShow" value=""/>
    <property key="labeling/dataDefined/Bold" value=""/>
    <property key="labeling/dataDefined/BufferColor" value=""/>
    <property key="labeling/dataDefined/BufferSize" value=""/>
    <property key="labeling/dataDefined/BufferTransp" value=""/>
    <property key="labeling/dataDefined/Color" value=""/>
    <property key="labeling/dataDefined/Family" value=""/>
    <property key="labeling/dataDefined/FontTransp" value=""/>
    <property key="labeling/dataDefined/Hali" value=""/>
    <property key="labeling/dataDefined/Italic" value=""/>
    <property key="labeling/dataDefined/LabelDistance" value=""/>
    <property key="labeling/dataDefined/MaxScale" value=""/>
    <property key="labeling/dataDefined/MinScale" value=""/>
    <property key="labeling/dataDefined/PositionX" value=""/>
    <property key="labeling/dataDefined/PositionY" value=""/>
    <property key="labeling/dataDefined/Rotation" value=""/>
    <property key="labeling/dataDefined/Show" value=""/>
    <property key="labeling/dataDefined/Size" value=""/>
    <property key="labeling/dataDefined/Strikeout" value=""/>
    <property key="labeling/dataDefined/Underline" value=""/>
    <property key="labeling/dataDefined/Vali" value=""/>
    <property key="labeling/decimals" value="0"/>
    <property key="labeling/displayAll" value="false"/>
    <property key="labeling/dist" value="0"/>
    <property key="labeling/distInMapUnits" value="false"/>
    <property key="labeling/enabled" value="true"/>
    <property key="labeling/fieldName" value="case when &quot;block&quot; &lt;> 'perimeter' or &quot;block&quot; is null then (&quot;parcel_number&quot; || '\n' || 'block '||&#xa;case when &quot;block&quot; is not null then &quot;block&quot; else '?' end ||', plot '||&#xa;case when&quot;serial_no&quot; is not null then&quot;serial_no&quot; else '?' end ||'\n'|| &#xa;case when &quot;official_area&quot; is not null then &quot;official_area&quot; else '?' end||'m² (o)'||'\n'||&#xa;&quot;comp_area&quot;||'m² (c)')  else &quot;scheme&quot; end"/>
    <property key="labeling/fontCapitals" value="0"/>
    <property key="labeling/fontFamily" value="Ubuntu"/>
    <property key="labeling/fontItalic" value="false"/>
    <property key="labeling/fontLetterSpacing" value="0"/>
    <property key="labeling/fontLimitPixelSize" value="false"/>
    <property key="labeling/fontMaxPixelSize" value="10000"/>
    <property key="labeling/fontMinPixelSize" value="3"/>
    <property key="labeling/fontSize" value="8"/>
    <property key="labeling/fontSizeInMapUnits" value="false"/>
    <property key="labeling/fontStrikeout" value="false"/>
    <property key="labeling/fontUnderline" value="false"/>
    <property key="labeling/fontWeight" value="50"/>
    <property key="labeling/fontWordSpacing" value="0"/>
    <property key="labeling/formatNumbers" value="false"/>
    <property key="labeling/isExpression" value="true"/>
    <property key="labeling/labelOffsetInMapUnits" value="true"/>
    <property key="labeling/labelPerPart" value="false"/>
    <property key="labeling/leftDirectionSymbol" value="&lt;"/>
    <property key="labeling/limitNumLabels" value="false"/>
    <property key="labeling/maxCurvedCharAngleIn" value="20"/>
    <property key="labeling/maxCurvedCharAngleOut" value="-20"/>
    <property key="labeling/maxNumLabels" value="2000"/>
    <property key="labeling/mergeLines" value="false"/>
    <property key="labeling/minFeatureSize" value="0"/>
    <property key="labeling/multilineAlign" value="0"/>
    <property key="labeling/multilineHeight" value="1"/>
    <property key="labeling/namedStyle" value="Regular"/>
    <property key="labeling/obstacle" value="true"/>
    <property key="labeling/placeDirectionSymbol" value="0"/>
    <property key="labeling/placement" value="5"/>
    <property key="labeling/placementFlags" value="0"/>
    <property key="labeling/plussign" value="true"/>
    <property key="labeling/preserveRotation" value="true"/>
    <property key="labeling/previewBkgrdColor" value="#ffffff"/>
    <property key="labeling/priority" value="10"/>
    <property key="labeling/reverseDirectionSymbol" value="false"/>
    <property key="labeling/rightDirectionSymbol" value=">"/>
    <property key="labeling/scaleMax" value="1500"/>
    <property key="labeling/scaleMin" value="1"/>
    <property key="labeling/textColorB" value="0"/>
    <property key="labeling/textColorG" value="0"/>
    <property key="labeling/textColorR" value="0"/>
    <property key="labeling/textTransp" value="0"/>
    <property key="labeling/upsidedownLabels" value="0"/>
    <property key="labeling/wrapChar" value=""/>
    <property key="labeling/xOffset" value="0"/>
    <property key="labeling/xQuadOffset" value="0"/>
    <property key="labeling/yOffset" value="0"/>
    <property key="labeling/yQuadOffset" value="0"/>
  </customproperties>
  <displayfield>parcel_id</displayfield>
  <label>0</label>
  <labelattributes>
    <label fieldname="" text="Label"/>
    <family fieldname="" name="Ubuntu"/>
    <size fieldname="" units="pt" value="12"/>
    <bold fieldname="" on="0"/>
    <italic fieldname="" on="0"/>
    <underline fieldname="" on="0"/>
    <strikeout fieldname="" on="0"/>
    <color fieldname="" red="0" blue="0" green="0"/>
    <x fieldname=""/>
    <y fieldname=""/>
    <offset x="0" y="0" units="pt" yfieldname="" xfieldname=""/>
    <angle fieldname="" value="0" auto="0"/>
    <alignment fieldname="" value="center"/>
    <buffercolor fieldname="" red="255" blue="255" green="255"/>
    <buffersize fieldname="" units="pt" value="1"/>
    <bufferenabled fieldname="" on=""/>
    <multilineenabled fieldname="" on=""/>
    <selectedonly on=""/>
  </labelattributes>
  <edittypes>
    <edittype editable="1" type="0" name="allocation"/>
    <edittype editable="1" type="0" name="block"/>
    <edittype editable="1" type="0" name="comp_area"/>
    <edittype editable="1" type="0" name="deeds_file"/>
    <edittype editable="1" type="0" name="file_number"/>
    <edittype editable="1" type="0" name="id"/>
    <edittype editable="1" type="0" name="official_area"/>
    <edittype editable="1" type="0" name="owner"/>
    <edittype editable="1" type="0" name="parcel_id"/>
    <edittype editable="1" type="0" name="parcel_number"/>
    <edittype editable="1" type="0" name="scheme"/>
    <edittype editable="1" type="0" name="serial_no"/>
  </edittypes>
  <editform>.</editform>
  <editforminit></editforminit>
  <annotationform>.</annotationform>
  <editorlayout>generatedlayout</editorlayout>
  <excludeAttributesWMS/>
  <excludeAttributesWFS/>
  <attributeactions/>
</qgis>
