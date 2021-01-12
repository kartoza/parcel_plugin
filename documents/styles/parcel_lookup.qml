<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" readOnly="0" version="3.16.2-Hannover" maxScale="0" minScale="1e+08" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <temporal enabled="0" durationField="" durationUnit="min" startExpression="" accumulate="0" mode="0" endField="" fixedDuration="0" startField="" endExpression="">
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
    <relation referencingLayer="parcel_lookup_b847ff48_ccca_4853_8f12_16a797c25a31" providerKey="postgres" layerName="allocation_cat" id="parcel_lookup_allocation_id_fkey" layerId="allocation_cat_e36ab2cd_9894_49a8_b33a_b581755718b4" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='allocation_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;allocation_cat&quot;" name="parcel_lookup_allocation_id_fkey" strength="Association" referencedLayer="allocation_cat_e36ab2cd_9894_49a8_b33a_b581755718b4">
      <fieldRef referencedField="allocation_cat" referencingField="allocation"/>
    </relation>
    <relation referencingLayer="parcel_lookup_b847ff48_ccca_4853_8f12_16a797c25a31" providerKey="postgres" layerName="local_govt" id="parcel_lookup_local_govt_id_fkey" layerId="local_govt_da78b4a8_e887_48ba_9c8e_0e1d703f9fda" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;local_govt&quot;" name="parcel_lookup_local_govt_id_fkey" strength="Association" referencedLayer="local_govt_da78b4a8_e887_48ba_9c8e_0e1d703f9fda">
      <fieldRef referencedField="id" referencingField="local_govt"/>
    </relation>
    <relation referencingLayer="parcel_lookup_b847ff48_ccca_4853_8f12_16a797c25a31" providerKey="postgres" layerName="prop_types" id="parcel_lookup_prop_type_id_fkey" layerId="prop_types_ca20e66a_c203_41bc_a45b_8a1c56b55d49" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;prop_types&quot;" name="parcel_lookup_prop_type_id_fkey" strength="Association" referencedLayer="prop_types_ca20e66a_c203_41bc_a45b_8a1c56b55d49">
      <fieldRef referencedField="id" referencingField="prop_type"/>
    </relation>
    <relation referencingLayer="parcel_lookup_b847ff48_ccca_4853_8f12_16a797c25a31" providerKey="postgres" layerName="schemes" id="parcel_lookup_scheme_id_fkey" layerId="schemes_c17af0aa_4b8b_4c10_9181_7cc3650e6b5c" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" name="parcel_lookup_scheme_id_fkey" strength="Association" referencedLayer="schemes_c17af0aa_4b8b_4c10_9181_7cc3650e6b5c">
      <fieldRef referencedField="id" referencingField="scheme"/>
    </relation>
    <relation referencingLayer="parcel_lookup_b847ff48_ccca_4853_8f12_16a797c25a31" providerKey="postgres" layerName="status_cat" id="parcel_lookup_status_cat_fkey" layerId="status_cat_4bc778da_85ea_4d99_8232_8a6f70aee12e" dataSource="dbname='gis' host=localhost port=25433 user='docker' key='status_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;status_cat&quot;" name="parcel_lookup_status_cat_fkey" strength="Association" referencedLayer="status_cat_4bc778da_85ea_4d99_8232_8a6f70aee12e">
      <fieldRef referencedField="status_cat" referencingField="status"/>
    </relation>
  </referencedLayers>
  <fieldConfiguration>
    <field configurationFlags="None" name="plot_sn">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="available">
      <editWidget type="CheckBox">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="scheme">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" type="bool" name="AllowAddFeatures"/>
            <Option value="true" type="bool" name="OrderByValue"/>
            <Option value="parcel_lookup_scheme_id_fkey" type="QString" name="Relation"/>
            <Option value="false" type="bool" name="ShowForm"/>
            <Option value="false" type="bool" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="block">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="local_govt">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" type="bool" name="AllowAddFeatures"/>
            <Option value="true" type="bool" name="OrderByValue"/>
            <Option value="parcel_lookup_local_govt_id_fkey" type="QString" name="Relation"/>
            <Option value="false" type="bool" name="ShowForm"/>
            <Option value="false" type="bool" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="prop_type">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" type="bool" name="AllowAddFeatures"/>
            <Option value="true" type="bool" name="OrderByValue"/>
            <Option value="parcel_lookup_prop_type_id_fkey" type="QString" name="Relation"/>
            <Option value="false" type="bool" name="ShowForm"/>
            <Option value="false" type="bool" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="file_number">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="allocation">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" type="bool" name="AllowAddFeatures"/>
            <Option value="true" type="bool" name="OrderByValue"/>
            <Option value="parcel_lookup_allocation_id_fkey" type="QString" name="Relation"/>
            <Option value="false" type="bool" name="ShowForm"/>
            <Option value="false" type="bool" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="manual_no">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="deeds_file">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="parcel_id">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="official_area">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="private">
      <editWidget type="CheckBox">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="status">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option value="true" type="bool" name="AllowAddFeatures"/>
            <Option value="true" type="bool" name="OrderByValue"/>
            <Option value="parcel_lookup_status_cat_fkey" type="QString" name="Relation"/>
            <Option value="false" type="bool" name="ShowForm"/>
            <Option value="false" type="bool" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="plot_sn" index="0" name=""/>
    <alias field="available" index="1" name=""/>
    <alias field="scheme" index="2" name=""/>
    <alias field="block" index="3" name=""/>
    <alias field="local_govt" index="4" name=""/>
    <alias field="prop_type" index="5" name=""/>
    <alias field="file_number" index="6" name=""/>
    <alias field="allocation" index="7" name=""/>
    <alias field="manual_no" index="8" name=""/>
    <alias field="deeds_file" index="9" name=""/>
    <alias field="parcel_id" index="10" name=""/>
    <alias field="official_area" index="11" name=""/>
    <alias field="private" index="12" name=""/>
    <alias field="status" index="13" name=""/>
  </aliases>
  <defaults>
    <default applyOnUpdate="0" field="plot_sn" expression=""/>
    <default applyOnUpdate="0" field="available" expression=""/>
    <default applyOnUpdate="0" field="scheme" expression=""/>
    <default applyOnUpdate="0" field="block" expression=""/>
    <default applyOnUpdate="0" field="local_govt" expression=""/>
    <default applyOnUpdate="0" field="prop_type" expression=""/>
    <default applyOnUpdate="0" field="file_number" expression=""/>
    <default applyOnUpdate="0" field="allocation" expression=""/>
    <default applyOnUpdate="0" field="manual_no" expression=""/>
    <default applyOnUpdate="0" field="deeds_file" expression=""/>
    <default applyOnUpdate="0" field="parcel_id" expression=""/>
    <default applyOnUpdate="0" field="official_area" expression=""/>
    <default applyOnUpdate="0" field="private" expression=""/>
    <default applyOnUpdate="0" field="status" expression=""/>
  </defaults>
  <constraints>
    <constraint field="plot_sn" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="available" constraints="1" unique_strength="0" notnull_strength="1" exp_strength="0"/>
    <constraint field="scheme" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="block" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="local_govt" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="prop_type" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="file_number" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="allocation" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="manual_no" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="deeds_file" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="parcel_id" constraints="3" unique_strength="1" notnull_strength="1" exp_strength="0"/>
    <constraint field="official_area" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="private" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
    <constraint field="status" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint field="plot_sn" desc="" exp=""/>
    <constraint field="available" desc="" exp=""/>
    <constraint field="scheme" desc="" exp=""/>
    <constraint field="block" desc="" exp=""/>
    <constraint field="local_govt" desc="" exp=""/>
    <constraint field="prop_type" desc="" exp=""/>
    <constraint field="file_number" desc="" exp=""/>
    <constraint field="allocation" desc="" exp=""/>
    <constraint field="manual_no" desc="" exp=""/>
    <constraint field="deeds_file" desc="" exp=""/>
    <constraint field="parcel_id" desc="" exp=""/>
    <constraint field="official_area" desc="" exp=""/>
    <constraint field="private" desc="" exp=""/>
    <constraint field="status" desc="" exp=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction value="{00000000-0000-0000-0000-000000000000}" key="Canvas"/>
  </attributeactions>
  <attributetableconfig actionWidgetStyle="dropDown" sortExpression="" sortOrder="0">
    <columns>
      <column type="field" name="plot_sn" width="-1" hidden="0"/>
      <column type="field" name="available" width="-1" hidden="0"/>
      <column type="field" name="scheme" width="-1" hidden="0"/>
      <column type="field" name="block" width="-1" hidden="0"/>
      <column type="field" name="local_govt" width="-1" hidden="0"/>
      <column type="field" name="prop_type" width="-1" hidden="0"/>
      <column type="field" name="file_number" width="-1" hidden="0"/>
      <column type="field" name="allocation" width="-1" hidden="0"/>
      <column type="field" name="manual_no" width="-1" hidden="0"/>
      <column type="field" name="deeds_file" width="-1" hidden="0"/>
      <column type="field" name="parcel_id" width="-1" hidden="0"/>
      <column type="field" name="official_area" width="-1" hidden="0"/>
      <column type="field" name="private" width="-1" hidden="0"/>
      <column type="field" name="status" width="-1" hidden="0"/>
      <column type="actions" width="-1" hidden="1"/>
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
    <attributeEditorContainer visibilityExpressionEnabled="0" showLabel="1" visibilityExpression="" groupBox="0" name="General" columnCount="2">
      <attributeEditorField showLabel="1" index="0" name="plot_sn"/>
      <attributeEditorField showLabel="1" index="2" name="scheme"/>
      <attributeEditorField showLabel="1" index="3" name="block"/>
      <attributeEditorField showLabel="1" index="4" name="local_govt"/>
      <attributeEditorField showLabel="1" index="5" name="prop_type"/>
      <attributeEditorField showLabel="1" index="6" name="file_number"/>
      <attributeEditorField showLabel="1" index="7" name="allocation"/>
      <attributeEditorField showLabel="1" index="8" name="manual_no"/>
      <attributeEditorField showLabel="1" index="9" name="deeds_file"/>
      <attributeEditorField showLabel="1" index="11" name="official_area"/>
      <attributeEditorField showLabel="1" index="13" name="status"/>
      <attributeEditorField showLabel="1" index="1" name="available"/>
      <attributeEditorField showLabel="1" index="12" name="private"/>
      <attributeEditorField showLabel="1" index="10" name="parcel_id"/>
    </attributeEditorContainer>
    <attributeEditorContainer visibilityExpressionEnabled="0" showLabel="1" visibilityExpression="" groupBox="0" name="parcel_def" columnCount="1">
      <attributeEditorRelation showLabel="1" forceSuppressFormPopup="0" label="" buttons="AllButtons" nmRelationId="" name="" relation=""/>
    </attributeEditorContainer>
    <attributeEditorContainer visibilityExpressionEnabled="0" showLabel="1" visibilityExpression="" groupBox="0" name="transactions" columnCount="1">
      <attributeEditorRelation showLabel="1" forceSuppressFormPopup="0" label="" buttons="AllButtons" nmRelationId="" name="" relation=""/>
    </attributeEditorContainer>
  </attributeEditorForm>
  <editable>
    <field editable="1" name="allocation"/>
    <field editable="1" name="available"/>
    <field editable="1" name="block"/>
    <field editable="1" name="deeds_file"/>
    <field editable="1" name="file_number"/>
    <field editable="1" name="local_govt"/>
    <field editable="1" name="manual_no"/>
    <field editable="1" name="official_area"/>
    <field editable="1" name="parcel_id"/>
    <field editable="1" name="plot_sn"/>
    <field editable="1" name="private"/>
    <field editable="1" name="prop_type"/>
    <field editable="1" name="scheme"/>
    <field editable="1" name="status"/>
  </editable>
  <labelOnTop>
    <field labelOnTop="0" name="allocation"/>
    <field labelOnTop="0" name="available"/>
    <field labelOnTop="0" name="block"/>
    <field labelOnTop="0" name="deeds_file"/>
    <field labelOnTop="0" name="file_number"/>
    <field labelOnTop="0" name="local_govt"/>
    <field labelOnTop="0" name="manual_no"/>
    <field labelOnTop="0" name="official_area"/>
    <field labelOnTop="0" name="parcel_id"/>
    <field labelOnTop="0" name="plot_sn"/>
    <field labelOnTop="0" name="private"/>
    <field labelOnTop="0" name="prop_type"/>
    <field labelOnTop="0" name="scheme"/>
    <field labelOnTop="0" name="status"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"parcel_id"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
