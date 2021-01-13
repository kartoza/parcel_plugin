<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" version="3.16.2-Hannover" minScale="1e+08" readOnly="0" maxScale="0" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <temporal accumulate="0" enabled="0" startField="" durationField="" endExpression="" fixedDuration="0" mode="0" durationUnit="min" endField="" startExpression="">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <property key="dualview/previewExpressions">
      <value>"description"</value>
    </property>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="variableNames"/>
    <property key="variableValues"/>
  </customproperties>
  <geometryOptions geometryPrecision="0" removeDuplicateNodes="0">
    <activeChecks/>
    <checkConfiguration/>
  </geometryOptions>
  <legend type="default-vector"/>
  <referencedLayers>
    <relation strength="Association" name="survey_ref_beacon_fkey" layerId="beacons_ecf1c285_b2d3_4ed2_88b7_b1229bdf1e0a" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='gid' srid=26332 type=Point checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;beacons&quot; (the_geom)" providerKey="postgres" referencingLayer="survey_95ff4d94_57c1_452f_a97a_44dd0e0d48a9" id="survey_ref_beacon_fkey" referencedLayer="beacons_ecf1c285_b2d3_4ed2_88b7_b1229bdf1e0a" layerName="beacons">
      <fieldRef referencedField="beacon" referencingField="ref_beacon"/>
    </relation>
    <relation strength="Association" name="survey_scheme_fkey" layerId="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" providerKey="postgres" referencingLayer="survey_95ff4d94_57c1_452f_a97a_44dd0e0d48a9" id="survey_scheme_fkey" referencedLayer="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5" layerName="Schemes">
      <fieldRef referencedField="id" referencingField="scheme"/>
    </relation>
  </referencedLayers>
  <fieldConfiguration>
    <field name="id" configurationFlags="None">
      <editWidget type="Hidden">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="plan_no" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="ref_beacon" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname='gis' host=localhost port=25433 user='docker' key='gid' srid=26332 type=Point checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;beacons&quot; (the_geom)"/>
            <Option name="ReferencedLayerId" type="QString" value="beacons_ecf1c285_b2d3_4ed2_88b7_b1229bdf1e0a"/>
            <Option name="ReferencedLayerName" type="QString" value="beacons"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="survey_ref_beacon_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="scheme" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5"/>
            <Option name="ReferencedLayerName" type="QString" value="Schemes"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="survey_scheme_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="description" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="id" name="Id" index="0"/>
    <alias field="plan_no" name="Plan Number" index="1"/>
    <alias field="ref_beacon" name="Reference Beacon" index="2"/>
    <alias field="scheme" name="Scheme" index="3"/>
    <alias field="description" name="Description" index="4"/>
  </aliases>
  <defaults>
    <default expression="" applyOnUpdate="0" field="id"/>
    <default expression="" applyOnUpdate="0" field="plan_no"/>
    <default expression="" applyOnUpdate="0" field="ref_beacon"/>
    <default expression="" applyOnUpdate="0" field="scheme"/>
    <default expression="" applyOnUpdate="0" field="description"/>
  </defaults>
  <constraints>
    <constraint notnull_strength="1" field="id" unique_strength="1" constraints="3" exp_strength="0"/>
    <constraint notnull_strength="1" field="plan_no" unique_strength="1" constraints="3" exp_strength="0"/>
    <constraint notnull_strength="1" field="ref_beacon" unique_strength="0" constraints="1" exp_strength="0"/>
    <constraint notnull_strength="0" field="scheme" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="description" unique_strength="0" constraints="0" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint field="id" exp="" desc=""/>
    <constraint field="plan_no" exp="" desc=""/>
    <constraint field="ref_beacon" exp="" desc=""/>
    <constraint field="scheme" exp="" desc=""/>
    <constraint field="description" exp="" desc=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{00000000-0000-0000-0000-000000000000}"/>
  </attributeactions>
  <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
    <columns>
      <column name="id" type="field" hidden="0" width="-1"/>
      <column name="plan_no" type="field" hidden="0" width="-1"/>
      <column name="ref_beacon" type="field" hidden="0" width="-1"/>
      <column name="scheme" type="field" hidden="0" width="-1"/>
      <column name="description" type="field" hidden="0" width="-1"/>
      <column type="actions" hidden="1" width="-1"/>
    </columns>
  </attributetableconfig>
  <conditionalstyles>
    <rowstyles/>
    <fieldstyles/>
  </conditionalstyles>
  <storedexpressions/>
  <editform tolerant="1"></editform>
  <editforminit/>
  <editforminitcodesource>0</editforminitcodesource>
  <editforminitfilepath></editforminitfilepath>
  <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
QGIS forms can have a Python function that is called when the form is
opened.

Use this function to add extra logic to your forms.

Enter the name of the function in the "Python Init function"
field.
An example follows:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
	geom = feature.geometry()
	control = dialog.findChild(QWidget, "MyLineEdit")
]]></editforminitcode>
  <featformsuppress>0</featformsuppress>
  <editorlayout>tablayout</editorlayout>
  <attributeEditorForm>
    <attributeEditorContainer visibilityExpressionEnabled="0" name="General" showLabel="1" visibilityExpression="" columnCount="2" groupBox="0">
      <attributeEditorField name="plan_no" showLabel="1" index="1"/>
      <attributeEditorField name="ref_beacon" showLabel="1" index="2"/>
      <attributeEditorField name="scheme" showLabel="1" index="3"/>
      <attributeEditorField name="description" showLabel="1" index="4"/>
      <attributeEditorField name="id" showLabel="1" index="0"/>
    </attributeEditorContainer>
  </attributeEditorForm>
  <editable>
    <field name="description" editable="1"/>
    <field name="id" editable="1"/>
    <field name="plan_no" editable="1"/>
    <field name="ref_beacon" editable="1"/>
    <field name="scheme" editable="1"/>
  </editable>
  <labelOnTop>
    <field name="description" labelOnTop="0"/>
    <field name="id" labelOnTop="0"/>
    <field name="plan_no" labelOnTop="0"/>
    <field name="ref_beacon" labelOnTop="0"/>
    <field name="scheme" labelOnTop="0"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"description"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
