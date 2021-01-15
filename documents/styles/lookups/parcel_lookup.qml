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
      <value>"parcel_id"</value>
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
    <relation strength="Association" name="parcel_lookup_allocation_id_fkey" layerId="allocation_cat_7a483598_2122_42ac_9b32_8d633ba6399c" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='allocation_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;allocation_cat&quot;" providerKey="postgres" referencingLayer="parcel_lookup_7b1fdc98_30be_4b57_8cf5_336db3ff2099" id="parcel_lookup_allocation_id_fkey" referencedLayer="allocation_cat_7a483598_2122_42ac_9b32_8d633ba6399c" layerName="Allocation_cat">
      <fieldRef referencedField="allocation_cat" referencingField="allocation"/>
    </relation>
    <relation strength="Association" name="parcel_lookup_local_govt_id_fkey" layerId="local_govt_bb30d8c8_fbfa_42e6_a66d_1204c919c09e" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;local_govt&quot;" providerKey="postgres" referencingLayer="parcel_lookup_7b1fdc98_30be_4b57_8cf5_336db3ff2099" id="parcel_lookup_local_govt_id_fkey" referencedLayer="local_govt_bb30d8c8_fbfa_42e6_a66d_1204c919c09e" layerName="Local_govt">
      <fieldRef referencedField="id" referencingField="local_govt"/>
    </relation>
    <relation strength="Association" name="parcel_lookup_prop_type_id_fkey" layerId="prop_types_b6a3cf3d_8288_4a78_b681_10a0d41203ff" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;prop_types&quot;" providerKey="postgres" referencingLayer="parcel_lookup_7b1fdc98_30be_4b57_8cf5_336db3ff2099" id="parcel_lookup_prop_type_id_fkey" referencedLayer="prop_types_b6a3cf3d_8288_4a78_b681_10a0d41203ff" layerName="Prop_types">
      <fieldRef referencedField="id" referencingField="prop_type"/>
    </relation>
    <relation strength="Association" name="parcel_lookup_scheme_id_fkey" layerId="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;" providerKey="postgres" referencingLayer="parcel_lookup_7b1fdc98_30be_4b57_8cf5_336db3ff2099" id="parcel_lookup_scheme_id_fkey" referencedLayer="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5" layerName="Schemes">
      <fieldRef referencedField="id" referencingField="scheme"/>
    </relation>
    <relation strength="Association" name="parcel_lookup_status_cat_fkey" layerId="status_cat_a4d50c7d_41bf_4d34_a102_02dd84b4a98a" dataSource="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='status_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;status_cat&quot;" providerKey="postgres" referencingLayer="parcel_lookup_7b1fdc98_30be_4b57_8cf5_336db3ff2099" id="parcel_lookup_status_cat_fkey" referencedLayer="status_cat_a4d50c7d_41bf_4d34_a102_02dd84b4a98a" layerName="Status_cat">
      <fieldRef referencedField="status_cat" referencingField="status"/>
    </relation>
  </referencedLayers>
  <fieldConfiguration>
    <field name="plot_sn" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="available" configurationFlags="None">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option name="CheckedState" type="QString" value=""/>
            <Option name="UncheckedState" type="QString" value=""/>
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
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;schemes&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="schemes_422921e0_833d_4ae0_8509_d8fd7175ebd5"/>
            <Option name="ReferencedLayerName" type="QString" value="Schemes"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="parcel_lookup_scheme_id_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
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
    <field name="local_govt" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;local_govt&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="local_govt_bb30d8c8_fbfa_42e6_a66d_1204c919c09e"/>
            <Option name="ReferencedLayerName" type="QString" value="Local_govt"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="parcel_lookup_local_govt_id_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="prop_type" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='id' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;prop_types&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="prop_types_b6a3cf3d_8288_4a78_b681_10a0d41203ff"/>
            <Option name="ReferencedLayerName" type="QString" value="Prop_types"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="parcel_lookup_prop_type_id_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="file_number" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="allocation" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='allocation_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;allocation_cat&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="allocation_cat_7a483598_2122_42ac_9b32_8d633ba6399c"/>
            <Option name="ReferencedLayerName" type="QString" value="Allocation_cat"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="parcel_lookup_allocation_id_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="manual_no" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="deeds_file" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="parcel_id" configurationFlags="None">
      <editWidget type="Hidden">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="official_area" configurationFlags="None">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option name="IsMultiline" type="bool" value="false"/>
            <Option name="UseHtml" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="private" configurationFlags="None">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option name="CheckedState" type="QString" value=""/>
            <Option name="UncheckedState" type="QString" value=""/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="status" configurationFlags="None">
      <editWidget type="RelationReference">
        <config>
          <Option type="Map">
            <Option name="AllowAddFeatures" type="bool" value="true"/>
            <Option name="AllowNULL" type="bool" value="false"/>
            <Option name="MapIdentification" type="bool" value="false"/>
            <Option name="OrderByValue" type="bool" value="true"/>
            <Option name="ReadOnly" type="bool" value="false"/>
            <Option name="ReferencedLayerDataSource" type="QString" value="dbname=':DATABASE' host=:DB_HOST port=:DB_PORT user=':DBOWNER' password=':DB_PASS'  key='status_cat' checkPrimaryKeyUnicity='1' table=&quot;public&quot;.&quot;status_cat&quot;"/>
            <Option name="ReferencedLayerId" type="QString" value="status_cat_a4d50c7d_41bf_4d34_a102_02dd84b4a98a"/>
            <Option name="ReferencedLayerName" type="QString" value="Status_cat"/>
            <Option name="ReferencedLayerProviderKey" type="QString" value="postgres"/>
            <Option name="Relation" type="QString" value="parcel_lookup_status_cat_fkey"/>
            <Option name="ShowForm" type="bool" value="false"/>
            <Option name="ShowOpenFormButton" type="bool" value="false"/>
          </Option>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="plot_sn" name="Plot SN" index="0"/>
    <alias field="available" name="Availability" index="1"/>
    <alias field="scheme" name="Scheme" index="2"/>
    <alias field="block" name="Block" index="3"/>
    <alias field="local_govt" name="Local overnment" index="4"/>
    <alias field="prop_type" name="Property Type" index="5"/>
    <alias field="file_number" name="File Number" index="6"/>
    <alias field="allocation" name="Allocation" index="7"/>
    <alias field="manual_no" name="Manual Number" index="8"/>
    <alias field="deeds_file" name="Deeds File" index="9"/>
    <alias field="parcel_id" name="Parcel Id" index="10"/>
    <alias field="official_area" name="Official Area" index="11"/>
    <alias field="private" name="Private" index="12"/>
    <alias field="status" name="Status" index="13"/>
  </aliases>
  <defaults>
    <default expression="" applyOnUpdate="0" field="plot_sn"/>
    <default expression="" applyOnUpdate="0" field="available"/>
    <default expression="" applyOnUpdate="0" field="scheme"/>
    <default expression="" applyOnUpdate="0" field="block"/>
    <default expression="" applyOnUpdate="0" field="local_govt"/>
    <default expression="" applyOnUpdate="0" field="prop_type"/>
    <default expression="" applyOnUpdate="0" field="file_number"/>
    <default expression="" applyOnUpdate="0" field="allocation"/>
    <default expression="" applyOnUpdate="0" field="manual_no"/>
    <default expression="" applyOnUpdate="0" field="deeds_file"/>
    <default expression="" applyOnUpdate="0" field="parcel_id"/>
    <default expression="" applyOnUpdate="0" field="official_area"/>
    <default expression="" applyOnUpdate="0" field="private"/>
    <default expression="" applyOnUpdate="0" field="status"/>
  </defaults>
  <constraints>
    <constraint notnull_strength="0" field="plot_sn" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="1" field="available" unique_strength="0" constraints="1" exp_strength="0"/>
    <constraint notnull_strength="0" field="scheme" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="block" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="local_govt" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="prop_type" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="file_number" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="allocation" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="manual_no" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="deeds_file" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="1" field="parcel_id" unique_strength="1" constraints="3" exp_strength="0"/>
    <constraint notnull_strength="0" field="official_area" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="private" unique_strength="0" constraints="0" exp_strength="0"/>
    <constraint notnull_strength="0" field="status" unique_strength="0" constraints="0" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint field="plot_sn" exp="" desc=""/>
    <constraint field="available" exp="" desc=""/>
    <constraint field="scheme" exp="" desc=""/>
    <constraint field="block" exp="" desc=""/>
    <constraint field="local_govt" exp="" desc=""/>
    <constraint field="prop_type" exp="" desc=""/>
    <constraint field="file_number" exp="" desc=""/>
    <constraint field="allocation" exp="" desc=""/>
    <constraint field="manual_no" exp="" desc=""/>
    <constraint field="deeds_file" exp="" desc=""/>
    <constraint field="parcel_id" exp="" desc=""/>
    <constraint field="official_area" exp="" desc=""/>
    <constraint field="private" exp="" desc=""/>
    <constraint field="status" exp="" desc=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{{00000000-0000-0000-0000-000000000000}}"/>
  </attributeactions>
  <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
    <columns>
      <column name="plot_sn" type="field" hidden="0" width="-1"/>
      <column name="available" type="field" hidden="0" width="-1"/>
      <column name="scheme" type="field" hidden="0" width="-1"/>
      <column name="block" type="field" hidden="0" width="-1"/>
      <column name="local_govt" type="field" hidden="0" width="-1"/>
      <column name="prop_type" type="field" hidden="0" width="-1"/>
      <column name="file_number" type="field" hidden="0" width="-1"/>
      <column name="allocation" type="field" hidden="0" width="-1"/>
      <column name="manual_no" type="field" hidden="0" width="-1"/>
      <column name="deeds_file" type="field" hidden="0" width="-1"/>
      <column name="parcel_id" type="field" hidden="0" width="-1"/>
      <column name="official_area" type="field" hidden="0" width="-1"/>
      <column name="private" type="field" hidden="0" width="-1"/>
      <column name="status" type="field" hidden="0" width="-1"/>
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
      <attributeEditorField name="plot_sn" showLabel="1" index="0"/>
      <attributeEditorField name="block" showLabel="1" index="3"/>
      <attributeEditorField name="file_number" showLabel="1" index="6"/>
      <attributeEditorField name="manual_no" showLabel="1" index="8"/>
      <attributeEditorField name="deeds_file" showLabel="1" index="9"/>
      <attributeEditorField name="official_area" showLabel="1" index="11"/>
      <attributeEditorField name="parcel_id" showLabel="1" index="10"/>
    </attributeEditorContainer>
    <attributeEditorContainer visibilityExpressionEnabled="0" name="Lookup" showLabel="1" visibilityExpression="" columnCount="1" groupBox="0">
      <attributeEditorField name="private" showLabel="1" index="12"/>
      <attributeEditorField name="scheme" showLabel="1" index="2"/>
      <attributeEditorField name="local_govt" showLabel="1" index="4"/>
      <attributeEditorField name="prop_type" showLabel="1" index="5"/>
      <attributeEditorField name="allocation" showLabel="1" index="7"/>
      <attributeEditorField name="status" showLabel="1" index="13"/>
      <attributeEditorField name="available" showLabel="1" index="1"/>
    </attributeEditorContainer>
  </attributeEditorForm>
  <editable>
    <field name="allocation" editable="1"/>
    <field name="available" editable="1"/>
    <field name="block" editable="1"/>
    <field name="deeds_file" editable="1"/>
    <field name="file_number" editable="1"/>
    <field name="local_govt" editable="1"/>
    <field name="manual_no" editable="1"/>
    <field name="official_area" editable="1"/>
    <field name="parcel_id" editable="1"/>
    <field name="plot_sn" editable="1"/>
    <field name="private" editable="1"/>
    <field name="prop_type" editable="1"/>
    <field name="scheme" editable="1"/>
    <field name="status" editable="1"/>
  </editable>
  <labelOnTop>
    <field name="allocation" labelOnTop="0"/>
    <field name="available" labelOnTop="0"/>
    <field name="block" labelOnTop="0"/>
    <field name="deeds_file" labelOnTop="0"/>
    <field name="file_number" labelOnTop="0"/>
    <field name="local_govt" labelOnTop="0"/>
    <field name="manual_no" labelOnTop="0"/>
    <field name="official_area" labelOnTop="0"/>
    <field name="parcel_id" labelOnTop="0"/>
    <field name="plot_sn" labelOnTop="0"/>
    <field name="private" labelOnTop="0"/>
    <field name="prop_type" labelOnTop="0"/>
    <field name="scheme" labelOnTop="0"/>
    <field name="status" labelOnTop="0"/>
  </labelOnTop>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>"parcel_id"</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>4</layerGeometryType>
</qgis>
