<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis minScale="1e+08" hasScaleBasedVisibilityFlag="0" maxScale="0" version="3.16.3-Hannover" styleCategories="AllStyleCategories" readOnly="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <temporal startExpression="" endField="" fixedDuration="0" accumulate="0" durationField="" mode="0" endExpression="" enabled="0" startField="" durationUnit="min">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <property value="0" key="embeddedWidgets/count"/>
    <property key="variableNames"/>
    <property key="variableValues"/>
  </customproperties>
  <geometryOptions removeDuplicateNodes="0" geometryPrecision="0">
    <activeChecks/>
    <checkConfiguration/>
  </geometryOptions>
  <legend type="default-vector"/>
  <referencedLayers>
    <relation referencedLayer="beacons_767b37a2_fd63_4cb4_aaa2_424e53c13cc2" layerName="Beacons" strength="Association" referencingLayer="survey_56473f07_4929_4494_921b_40b73e3324a5" providerKey="postgres" name="survey_ref_beacon_fkey" layerId="beacons_767b37a2_fd63_4cb4_aaa2_424e53c13cc2" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS' key='gid' srid=:CRS type=Point checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;beacons&quot; (the_geom)" id="survey_ref_beacon_fkey">
      <fieldRef referencingField="ref_beacon" referencedField="beacon"/>
    </relation>
    <relation referencedLayer="schemes_ac1eeb89_57e3_47cc_849d_4849da44e2ef" layerName="Schemes" strength="Association" referencingLayer="survey_56473f07_4929_4494_921b_40b73e3324a5" providerKey="postgres" name="survey_scheme_fkey" layerId="schemes_ac1eeb89_57e3_47cc_849d_4849da44e2ef" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" id="survey_scheme_fkey">
      <fieldRef referencingField="scheme" referencedField="id"/>
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
            <Option value="false" name="IsMultiline" type="bool"/>
            <Option value="false" name="UseHtml" type="bool"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="ref_beacon" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" name="AllowAddFeatures" type="bool"/>
            <Option value="false" name="AllowNULL" type="bool"/>
            <Option value="false" name="MapIdentification" type="bool"/>
            <Option value="true" name="OrderByValue" type="bool"/>
            <Option value="false" name="ReadOnly" type="bool"/>
            <Option value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS' key='gid' srid=:CRS type=Point checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;beacons&quot; (the_geom)" name="ReferencedLayerDataSource" type="QString"/>
            <Option value="beacons_767b37a2_fd63_4cb4_aaa2_424e53c13cc2" name="ReferencedLayerId" type="QString"/>
            <Option value="Beacons" name="ReferencedLayerName" type="QString"/>
            <Option value="postgres" name="ReferencedLayerProviderKey" type="QString"/>
            <Option value="survey_ref_beacon_fkey" name="Relation" type="QString"/>
            <Option value="false" name="ShowForm" type="bool"/>
            <Option value="false" name="ShowOpenFormButton" type="bool"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="scheme" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" name="AllowAddFeatures" type="bool"/>
            <Option value="false" name="AllowNULL" type="bool"/>
            <Option value="false" name="MapIdentification" type="bool"/>
            <Option value="true" name="OrderByValue" type="bool"/>
            <Option value="false" name="ReadOnly" type="bool"/>
            <Option value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" name="ReferencedLayerDataSource" type="QString"/>
            <Option value="schemes_ac1eeb89_57e3_47cc_849d_4849da44e2ef" name="ReferencedLayerId" type="QString"/>
            <Option value="Schemes" name="ReferencedLayerName" type="QString"/>
            <Option value="postgres" name="ReferencedLayerProviderKey" type="QString"/>
            <Option value="survey_scheme_fkey" name="Relation" type="QString"/>
            <Option value="false" name="ShowForm" type="bool"/>
            <Option value="false" name="ShowOpenFormButton" type="bool"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="description" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option value="false" name="IsMultiline" type="bool"/>
            <Option value="false" name="UseHtml" type="bool"/>
          </Option>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias index="0" name="" field="id"/>
    <alias index="1" name="Plan Number" field="plan_no"/>
    <alias index="2" name="Reference Beacon" field="ref_beacon"/>
    <alias index="3" name="Scheme" field="scheme"/>
    <alias index="4" name="Description" field="description"/>
  </aliases>
  <defaults>
    <default applyOnUpdate="0" field="id" expression=""/>
    <default applyOnUpdate="0" field="plan_no" expression=""/>
    <default applyOnUpdate="0" field="ref_beacon" expression=""/>
    <default applyOnUpdate="0" field="scheme" expression=""/>
    <default applyOnUpdate="0" field="description" expression=""/>
  </defaults>
  <constraints>
    <constraint constraints="3" unique_strength="1" field="id" exp_strength="0" notnull_strength="1"/>
    <constraint constraints="3" unique_strength="1" field="plan_no" exp_strength="0" notnull_strength="1"/>
    <constraint constraints="1" unique_strength="0" field="ref_beacon" exp_strength="0" notnull_strength="1"/>
    <constraint constraints="0" unique_strength="0" field="scheme" exp_strength="0" notnull_strength="0"/>
    <constraint constraints="0" unique_strength="0" field="description" exp_strength="0" notnull_strength="0"/>
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
    <defaultAction value="{{00000000-0000-0000-0000-000000000000}}" key="Canvas"/>
  </attributeactions>
  <attributetableconfig actionWidgetStyle="dropDown" sortExpression="" sortOrder="0">
    <columns>
      <column hidden="0" name="id" width="-1" type="field"/>
      <column hidden="0" name="plan_no" width="-1" type="field"/>
      <column hidden="0" name="ref_beacon" width="-1" type="field"/>
      <column hidden="0" name="scheme" width="-1" type="field"/>
      <column hidden="0" name="description" width="-1" type="field"/>
      <column hidden="1" width="-1" type="actions"/>
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
    <attributeEditorContainer showLabel="1" visibilityExpressionEnabled="0" visibilityExpression="" name="General" columnCount="2" groupBox="0">
      <attributeEditorField showLabel="1" index="1" name="plan_no"/>
      <attributeEditorField showLabel="1" index="2" name="ref_beacon"/>
      <attributeEditorField showLabel="1" index="3" name="scheme"/>
      <attributeEditorField showLabel="1" index="4" name="description"/>
      <attributeEditorField showLabel="1" index="0" name="id"/>
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
    <field labelOnTop="0" name="description"/>
    <field labelOnTop="0" name="id"/>
    <field labelOnTop="0" name="plan_no"/>
    <field labelOnTop="0" name="ref_beacon"/>
    <field labelOnTop="0" name="scheme"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"description"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
