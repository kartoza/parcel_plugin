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
    <field name="status_cat" configurationFlags="None">
      <editWidget type="Hidden">
        <config>
          <Option/>
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
    <alias field="status_cat" name="Status Category" index="0"/>
    <alias field="description" name="Description" index="1"/>
  </aliases>
  <defaults>
    <default expression="" applyOnUpdate="0" field="status_cat"/>
    <default expression="" applyOnUpdate="0" field="description"/>
  </defaults>
  <constraints>
    <constraint notnull_strength="1" field="status_cat" unique_strength="1" constraints="3" exp_strength="0"/>
    <constraint notnull_strength="1" field="description" unique_strength="0" constraints="1" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint field="status_cat" exp="" desc=""/>
    <constraint field="description" exp="" desc=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{{00000000-0000-0000-0000-000000000000}}"/>
  </attributeactions>
  <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
    <columns>
      <column name="status_cat" type="field" hidden="0" width="-1"/>
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
    <attributeEditorField name="description" showLabel="1" index="1"/>
    <attributeEditorField name="status_cat" showLabel="1" index="0"/>
  </attributeEditorForm>
  <editable>
    <field name="description" editable="1"/>
    <field name="status_cat" editable="1"/>
  </editable>
  <labelOnTop>
    <field name="description" labelOnTop="0"/>
    <field name="status_cat" labelOnTop="0"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"description"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
