create or replace type body ut_compound_data_value as
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2017 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  overriding member function get_object_info return varchar2 is
  begin
    return self.data_type||' [ count = '||self.elements_count||' ]';
  end;

  overriding member function is_null return boolean is
  begin
    return ut_utils.int_to_boolean(self.is_data_null);
  end;

  overriding member function is_diffable return boolean is
  begin
    return true;
  end;

  member function is_empty return boolean is
  begin
    return self.elements_count = 0;
  end;

  overriding member function is_multi_line return boolean is
  begin
    return not self.is_null() and not self.is_empty();
  end;

  overriding member function compare_implementation(a_other ut_data_value) return integer is
  begin
    return compare_implementation( a_other, null, null);
  end;

  overriding member function to_string return varchar2 is
    l_results       ut_utils.t_clob_tab;
    c_max_rows      constant integer := 20;
    l_result        clob;
    l_result_string varchar2(32767);
  begin
    if not self.is_null() then
      dbms_lob.createtemporary(l_result, true);
      ut_utils.append_to_clob(l_result,'Data:'||chr(10));
      --return first c_max_rows rows
      execute immediate '
          select xmlserialize( content ucd.item_data no indent)
            from '|| ut_utils.ut_owner ||'.ut_compound_data_tmp ucd
           where ucd.data_id = :data_id
             and ucd.item_no <= :max_rows'
        bulk collect into l_results using self.data_id, c_max_rows;

      ut_utils.append_to_clob(l_result,l_results);

      l_result_string := ut_utils.to_string(l_result,null);
      dbms_lob.freetemporary(l_result);
    end if;
    return l_result_string;
  end;

  overriding member function diff( a_other ut_data_value, a_exclude_xpath varchar2, a_include_xpath varchar2 ) return varchar2 is
    l_result            clob;
  l_result_string     varchar2(32767);
  begin
    l_result := get_data_diff(a_other, a_exclude_xpath, a_include_xpath);
    l_result_string := ut_utils.to_string(l_result,null);
    dbms_lob.freetemporary(l_result);
    return l_result_string;
  end;

  member function get_data_diff( a_other ut_data_value, a_exclude_xpath varchar2, a_include_xpath varchar2 ) return clob is
    c_max_rows          constant integer := 20;
    l_result            clob;
    l_results           ut_utils.t_clob_tab := ut_utils.t_clob_tab();
    l_message           varchar2(32767);
    l_ut_owner          varchar2(250) := ut_utils.ut_owner;
    l_diff_row_count    integer;
    l_actual            ut_compound_data_value;
    l_diff_id           ut_compound_data_helper.t_hash;
    l_row_diffs         ut_compound_data_helper.tt_row_diffs;
  begin
    if not a_other is of (ut_compound_data_value) then
      raise value_error;
    end if;
    l_actual := treat(a_other as ut_compound_data_value);

    dbms_lob.createtemporary(l_result,true);

    --diff rows and row elements
    l_diff_id := ut_compound_data_helper.get_hash(self.data_id||l_actual.data_id);
    -- First tell how many rows are different
    execute immediate 'select count(*) from ' || l_ut_owner || '.ut_compound_data_diff_tmp where diff_id = :diff_id' into l_diff_row_count using l_diff_id;

    if l_diff_row_count > 0  then
      l_row_diffs := ut_compound_data_helper.get_rows_diff(
          self.data_id, l_actual.data_id, l_diff_id, c_max_rows, a_exclude_xpath, a_include_xpath
      );
      l_message := chr(10)
                   ||'Rows: [ ' || l_diff_row_count ||' differences'
                   ||  case when  l_diff_row_count > c_max_rows and l_row_diffs.count > 0 then ', showing first '||c_max_rows end
                   ||' ]' || chr(10)
                   || case when l_row_diffs.count = 0
        then '  All rows are different as the columns are not matching.' end;
      ut_utils.append_to_clob( l_result, l_message );
      for i in 1 .. l_row_diffs.count loop
        l_results.extend;
        l_results(l_results.last) := '  Row No. '||l_row_diffs(i).rn||' - '||rpad(l_row_diffs(i).diff_type,10)||l_row_diffs(i).diffed_row;
      end loop;
      ut_utils.append_to_clob(l_result,l_results);
    end if;
    return l_result;
  end;

  member function compare_implementation(a_other ut_data_value, a_exclude_xpath varchar2, a_include_xpath varchar2) return integer is
    l_other           ut_compound_data_value;
    l_ut_owner        varchar2(250) := ut_utils.ut_owner;
    l_column_filter   varchar2(32767);
    l_diff_id         ut_compound_data_helper.t_hash;
    l_result          integer;
    --the XML stylesheet is applied on XML representation of data to exclude column names from comparison
    --column names and data-types are compared separately
    l_xml_data_fmt    constant xmltype := xmltype(
        q'[<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:strip-space elements="*" />
          <xsl:template match="/child::*">
              <xsl:for-each select="child::node()">
                  <xsl:choose>
                      <xsl:when test="*[*]"><xsl:copy-of select="node()"/></xsl:when>
                      <xsl:when test="position()=last()"><xsl:value-of select="normalize-space(.)"/><xsl:text>&#xD;</xsl:text></xsl:when>
                      <xsl:otherwise><xsl:value-of select="normalize-space(.)"/>,</xsl:otherwise>
                  </xsl:choose>
              </xsl:for-each>
          </xsl:template>
          </xsl:stylesheet>]');
  begin
    if not a_other is of (ut_compound_data_value) then
      raise value_error;
    end if;

    l_other   := treat(a_other as ut_compound_data_value);

    l_diff_id := ut_compound_data_helper.get_hash(self.data_id||l_other.data_id);
    l_column_filter := ut_compound_data_helper.get_columns_filter(a_exclude_xpath, a_include_xpath);
    -- Find differences
    execute immediate 'insert into ' || l_ut_owner || '.ut_compound_data_diff_tmp ( diff_id, item_no )
                        select :diff_id, nvl(exp.item_no, act.item_no)
                          from (select '||l_column_filter||', ucd.item_no
                                  from ' || l_ut_owner || '.ut_compound_data_tmp ucd where ucd.data_id = :self_guid) exp
                          full outer join
                               (select '||l_column_filter||', ucd.item_no
                                  from ' || l_ut_owner || '.ut_compound_data_tmp ucd where ucd.data_id = :l_other_guid) act
                            on exp.item_no = act.item_no '||
                        'where nvl( dbms_lob.compare(' ||
                                     /*the xmltransform removes column names and leaves column data to be compared only*/
                                     '  xmltransform(exp.item_data, :l_xml_data_fmt).getclobval()' ||
                                     ', xmltransform(act.item_data, :l_xml_data_fmt).getclobval())' ||
                                 ',1' ||
                                 ') != 0'
      using in l_diff_id, a_exclude_xpath, a_include_xpath, self.data_id,
         a_exclude_xpath, a_include_xpath, l_other.data_id, l_xml_data_fmt, l_xml_data_fmt;

    --result is OK only if both are same
    if sql%rowcount = 0 and self.elements_count = l_other.elements_count then
      l_result := 0;
    else
      l_result := 1;
    end if;
    return l_result;
  end;

end;
/
