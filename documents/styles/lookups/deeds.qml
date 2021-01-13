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
    <property key="embeddedWidgets/count" value="0"/>
    <property key="variableNames"/>
    <property key="variableValues"/>
  </customproperties>
  <geometryOptions geometryPrecision="0" removeDuplicateNodes="0">
    <activeChecks/>
    <checkConfiguration/>
  </geometryOptions>
  <legend type="default-vector"/>
  <referencedLayers/>
  <fieldConfiguration>
    <field name="fileno" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="planno" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="instrument" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="grantor" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="grantee" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="block" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="plot" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="location" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="deed_sn" configurationFlags="None">
      <editWidget type="Hidden">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="fileno" name="File Number" index="0"/>
    <alias field="planno" name="Plan Number" index="1"/>
    <alias field="instrument" name="Instrument" index="2"/>
    <alias field="grantor" name="Grantor" index="3"/>
    <alias field="grantee" name="Grantee" index="4"/>
    <alias field="block" name="Block" index="5"/>
    <alias field="plot" name="Plot" index="6"/>
    <alias field="location" name="Location" index="7"/>
    <alias field="deed_sn" name="Deeds SN" index="8"/>
  </aliases>
  <defaults>
    <default expression="" applyOnUpdate="0" field="fileno"/>
    <default expression="" applyOnUpdate="0" field="planno"/>
    <default expression="" applyOnUpdate="0" field="instrument"/>
    <default expression="" applyOnUpdate="0" field="grantor"/>
    <default expression="" applyOnUpdate="0" field="grantee"/>
    <default expression="" applyOnUpdate="0" field="block"/>
    <default expression="" applyOnUpdate="0" field="plot"/>
    <default expression="" applyOnUpdate="0" field="location"/>
    <default expression="" applyOnUpdate="0" field="deed_sn"/>
  </defaults>
  <constraints>
    <constraint notnull_strength="0" field="fileno" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="planno" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="instrument" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="grantor" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="grantee" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="block" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="plot" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="location" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="1" field="deed_sn" unique_strength="1" constraints="3" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint field="fileno" exp="" desc=""/>
    <constraint field="planno" exp="" desc=""/>
    <constraint field="instrument" exp="" desc=""/>
    <constraint field="grantor" exp="" desc=""/>
    <constraint field="grantee" exp="" desc=""/>
    <constraint field="block" exp="" desc=""/>
    <constraint field="plot" exp="" desc=""/>
    <constraint field="location" exp="" desc=""/>
    <constraint field="deed_sn" exp="" desc=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{00000000-0000-0000-0000-000000000000}"/>
  </attributeactions>
  <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
    <columns>
      <column name="fileno" type="field" hidden="0" width="-1"/>
      <column name="planno" type="field" hidden="0" width="-1"/>
      <column name="instrument" type="field" hidden="0" width="-1"/>
      <column name="grantor" type="field" hidden="0" width="-1"/>
      <column name="grantee" type="field" hidden="0" width="-1"/>
      <column name="block" type="field" hidden="0" width="-1"/>
      <column name="plot" type="field" hidden="0" width="-1"/>
      <column name="location" type="field" hidden="0" width="-1"/>
      <column name="deed_sn" type="field" hidden="0" width="-1"/>
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
    <attributeEditorField name="fileno" showLabel="1" index="0"/>
    <attributeEditorField name="planno" showLabel="1" index="1"/>
    <attributeEditorField name="instrument" showLabel="1" index="2"/>
    <attributeEditorField name="grantor" showLabel="1" index="3"/>
    <attributeEditorField name="grantee" showLabel="1" index="4"/>
    <attributeEditorField name="block" showLabel="1" index="5"/>
    <attributeEditorField name="plot" showLabel="1" index="6"/>
    <attributeEditorField name="location" showLabel="1" index="7"/>
    <attributeEditorField name="deed_sn" showLabel="1" index="8"/>
  </attributeEditorForm>
  <editable>
    <field name="block" editable="1"/>
    <field name="deed_sn" editable="1"/>
    <field name="fileno" editable="1"/>
    <field name="grantee" editable="1"/>
    <field name="grantor" editable="1"/>
    <field name="instrument" editable="1"/>
    <field name="location" editable="1"/>
    <field name="planno" editable="1"/>
    <field name="plot" editable="1"/>
  </editable>
  <labelOnTop>
    <field name="block" labelOnTop="0"/>
    <field name="deed_sn" labelOnTop="0"/>
    <field name="fileno" labelOnTop="0"/>
    <field name="grantee" labelOnTop="0"/>
    <field name="grantor" labelOnTop="0"/>
    <field name="instrument" labelOnTop="0"/>
    <field name="location" labelOnTop="0"/>
    <field name="planno" labelOnTop="0"/>
    <field name="plot" labelOnTop="0"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"fileno"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
