<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" minScale="1e+08" readOnly="0" hasScaleBasedVisibilityFlag="0" styleCategories="AllStyleCategories" version="3.16.2-Hannover">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <temporal fixedDuration="0" durationField="" startExpression="" enabled="0" mode="0" endField="" startField="" accumulate="0" durationUnit="min" endExpression="">
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
  <referencedLayers>
    <relation dataSource="dbname='gis' host=localhost port=25433 user='docker' key='allocation_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;allocation_cat&quot;" strength="Association" referencedLayer="Allocation_cat_10ac040f_8dda_40b3_a748_bab6b522f22f" layerName="Allocation_cat" providerKey="postgres" layerId="Allocation_cat_10ac040f_8dda_40b3_a748_bab6b522f22f" referencingLayer="Parcel_lookup_0ae946da_fb76_4743_bf0f_6be1a081f808" id="parcel_lookup_allocation_id_fkey" name="parcel_lookup_allocation_id_fkey">
      <fieldRef referencedField="allocation_cat" referencingField="allocation"/>
    </relation>
    <relation dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;local_govt&quot;" strength="Association" referencedLayer="Local_govt_c0c745b6_7aed_4c38_8fe9_8a3e774d12a5" layerName="Local_govt" providerKey="postgres" layerId="Local_govt_c0c745b6_7aed_4c38_8fe9_8a3e774d12a5" referencingLayer="Parcel_lookup_0ae946da_fb76_4743_bf0f_6be1a081f808" id="parcel_lookup_local_govt_id_fkey" name="parcel_lookup_local_govt_id_fkey">
      <fieldRef referencedField="id" referencingField="local_govt"/>
    </relation>
    <relation dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;prop_types&quot;" strength="Association" referencedLayer="Prop_types_fc594dfa_9daa_4b66_9ca5_7d346985df6c" layerName="Prop_types" providerKey="postgres" layerId="Prop_types_fc594dfa_9daa_4b66_9ca5_7d346985df6c" referencingLayer="Parcel_lookup_0ae946da_fb76_4743_bf0f_6be1a081f808" id="parcel_lookup_prop_type_id_fkey" name="parcel_lookup_prop_type_id_fkey">
      <fieldRef referencedField="id" referencingField="prop_type"/>
    </relation>
    <relation dataSource="dbname='gis' host=localhost port=25433 user='docker' key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" strength="Association" referencedLayer="Schemes_4ba3c59d_fee6_4041_8e44_62262cf09c4e" layerName="Schemes" providerKey="postgres" layerId="Schemes_4ba3c59d_fee6_4041_8e44_62262cf09c4e" referencingLayer="Parcel_lookup_0ae946da_fb76_4743_bf0f_6be1a081f808" id="parcel_lookup_scheme_id_fkey" name="parcel_lookup_scheme_id_fkey">
      <fieldRef referencedField="id" referencingField="scheme"/>
    </relation>
    <relation dataSource="dbname='gis' host=localhost port=25433 user='docker' key='status_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;status_cat&quot;" strength="Association" referencedLayer="Status_cat_43adb69f_62ec_40c3_b082_59efb2f645c9" layerName="Status_cat" providerKey="postgres" layerId="Status_cat_43adb69f_62ec_40c3_b082_59efb2f645c9" referencingLayer="Parcel_lookup_0ae946da_fb76_4743_bf0f_6be1a081f808" id="parcel_lookup_status_cat_fkey" name="parcel_lookup_status_cat_fkey">
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
            <Option type="bool" value="true" name="AllowAddFeatures"/>
            <Option type="bool" value="true" name="OrderByValue"/>
            <Option type="QString" value="parcel_lookup_scheme_id_fkey" name="Relation"/>
            <Option type="bool" value="false" name="ShowForm"/>
            <Option type="bool" value="false" name="ShowOpenFormButton"/>
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
            <Option type="bool" value="true" name="AllowAddFeatures"/>
            <Option type="bool" value="true" name="OrderByValue"/>
            <Option type="QString" value="parcel_lookup_local_govt_id_fkey" name="Relation"/>
            <Option type="bool" value="false" name="ShowForm"/>
            <Option type="bool" value="false" name="ShowOpenFormButton"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field configurationFlags="None" name="prop_type">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowAddFeatures"/>
            <Option type="bool" value="true" name="OrderByValue"/>
            <Option type="QString" value="parcel_lookup_prop_type_id_fkey" name="Relation"/>
            <Option type="bool" value="false" name="ShowForm"/>
            <Option type="bool" value="false" name="ShowOpenFormButton"/>
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
            <Option type="bool" value="true" name="AllowAddFeatures"/>
            <Option type="bool" value="true" name="OrderByValue"/>
            <Option type="QString" value="parcel_lookup_allocation_id_fkey" name="Relation"/>
            <Option type="bool" value="false" name="ShowForm"/>
            <Option type="bool" value="false" name="ShowOpenFormButton"/>
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
            <Option type="bool" value="true" name="AllowAddFeatures"/>
            <Option type="bool" value="true" name="OrderByValue"/>
            <Option type="QString" value="parcel_lookup_status_cat_fkey" name="Relation"/>
            <Option type="bool" value="false" name="ShowForm"/>
            <Option type="bool" value="false" name="ShowOpenFormButton"/>
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
    <default field="plot_sn" expression="" applyOnUpdate="0"/>
    <default field="available" expression="" applyOnUpdate="0"/>
    <default field="scheme" expression="" applyOnUpdate="0"/>
    <default field="block" expression="" applyOnUpdate="0"/>
    <default field="local_govt" expression="" applyOnUpdate="0"/>
    <default field="prop_type" expression="" applyOnUpdate="0"/>
    <default field="file_number" expression="" applyOnUpdate="0"/>
    <default field="allocation" expression="" applyOnUpdate="0"/>
    <default field="manual_no" expression="" applyOnUpdate="0"/>
    <default field="deeds_file" expression="" applyOnUpdate="0"/>
    <default field="parcel_id" expression="" applyOnUpdate="0"/>
    <default field="official_area" expression="" applyOnUpdate="0"/>
    <default field="private" expression="" applyOnUpdate="0"/>
    <default field="status" expression="" applyOnUpdate="0"/>
  </defaults>
  <constraints>
    <constraint unique_strength="0" notnull_strength="0" field="plot_sn" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="1" field="available" constraints="1" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="scheme" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="block" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="local_govt" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="prop_type" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="file_number" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="allocation" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="manual_no" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="deeds_file" constraints="0" exp_strength="0"/>
    <constraint unique_strength="1" notnull_strength="1" field="parcel_id" constraints="3" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="official_area" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="private" constraints="0" exp_strength="0"/>
    <constraint unique_strength="0" notnull_strength="0" field="status" constraints="0" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint desc="" field="plot_sn" exp=""/>
    <constraint desc="" field="available" exp=""/>
    <constraint desc="" field="scheme" exp=""/>
    <constraint desc="" field="block" exp=""/>
    <constraint desc="" field="local_govt" exp=""/>
    <constraint desc="" field="prop_type" exp=""/>
    <constraint desc="" field="file_number" exp=""/>
    <constraint desc="" field="allocation" exp=""/>
    <constraint desc="" field="manual_no" exp=""/>
    <constraint desc="" field="deeds_file" exp=""/>
    <constraint desc="" field="parcel_id" exp=""/>
    <constraint desc="" field="official_area" exp=""/>
    <constraint desc="" field="private" exp=""/>
    <constraint desc="" field="status" exp=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{00000000-0000-0000-0000-000000000000}"/>
  </attributeactions>
  <attributetableconfig actionWidgetStyle="dropDown" sortOrder="0" sortExpression="">
    <columns>
      <column type="field" width="-1" hidden="0" name="plot_sn"/>
      <column type="field" width="-1" hidden="0" name="available"/>
      <column type="field" width="-1" hidden="0" name="scheme"/>
      <column type="field" width="-1" hidden="0" name="block"/>
      <column type="field" width="-1" hidden="0" name="local_govt"/>
      <column type="field" width="-1" hidden="0" name="prop_type"/>
      <column type="field" width="-1" hidden="0" name="file_number"/>
      <column type="field" width="-1" hidden="0" name="allocation"/>
      <column type="field" width="-1" hidden="0" name="manual_no"/>
      <column type="field" width="-1" hidden="0" name="deeds_file"/>
      <column type="field" width="-1" hidden="0" name="parcel_id"/>
      <column type="field" width="-1" hidden="0" name="official_area"/>
      <column type="field" width="-1" hidden="0" name="private"/>
      <column type="field" width="-1" hidden="0" name="status"/>
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
    <attributeEditorContainer showLabel="1" visibilityExpressionEnabled="0" visibilityExpression="" groupBox="0" name="General" columnCount="2">
      <attributeEditorField showLabel="1" name="plot_sn" index="0"/>
      <attributeEditorField showLabel="1" name="scheme" index="2"/>
      <attributeEditorField showLabel="1" name="block" index="3"/>
      <attributeEditorField showLabel="1" name="local_govt" index="4"/>
      <attributeEditorField showLabel="1" name="prop_type" index="5"/>
      <attributeEditorField showLabel="1" name="file_number" index="6"/>
      <attributeEditorField showLabel="1" name="allocation" index="7"/>
      <attributeEditorField showLabel="1" name="manual_no" index="8"/>
      <attributeEditorField showLabel="1" name="deeds_file" index="9"/>
      <attributeEditorField showLabel="1" name="official_area" index="11"/>
      <attributeEditorField showLabel="1" name="status" index="13"/>
      <attributeEditorField showLabel="1" name="available" index="1"/>
      <attributeEditorField showLabel="1" name="private" index="12"/>
      <attributeEditorField showLabel="1" name="parcel_id" index="10"/>
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
