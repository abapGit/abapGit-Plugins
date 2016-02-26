CLASS lcl_tlogo_bridge IMPLEMENTATION.

  METHOD constructor.
    mv_object = iv_object.
    mv_object_name = iv_object_name.

*    Default configuration for validation of metadata
    mv_tolerate_additional_tables   = abap_false.
    mv_tolerate_deviating_fields    = abap_true.
    mv_tolerate_deviating_types     = abap_false.

    CONSTANTS co_logical_transport_object TYPE c LENGTH 1 VALUE 'L'.

* get the TLOGO properties as stored in transaction SOBJ

* object header
    SELECT SINGLE * FROM objh INTO ms_object_header
      WHERE objectname = mv_object
      AND   objecttype = co_logical_transport_object.

    IF ms_object_header IS INITIAL.
      RAISE EXCEPTION TYPE lcx_obj_exception
        EXPORTING
          iv_text = |Unsupported object-type { mv_object }|.
    ENDIF.

* object tables
    SELECT * FROM objsl INTO CORRESPONDING FIELDS OF TABLE mt_object_table
      WHERE objectname = mv_object
      AND   objecttype = co_logical_transport_object.
    IF mt_object_table IS INITIAL.
      RAISE EXCEPTION TYPE lcx_obj_exception
        EXPORTING
          iv_text = |Obviously corrupted object-type { mv_object }: No tables defined|.
    ENDIF.

*  field catalog of table structures in current system
    FIELD-SYMBOLS <ls_object_table> LIKE LINE OF mt_object_table.
    DATA lo_structdescr     TYPE REF TO cl_abap_structdescr.
    DATA lt_included_view   TYPE cl_abap_structdescr=>included_view.
    DATA ls_component       LIKE LINE OF lt_included_view.
    DATA ls_field_cat_comp  LIKE LINE OF <ls_object_table>-field_catalog.
    DATA lo_elemdescr       TYPE REF TO cl_abap_elemdescr.
    DATA lt_dfies           TYPE dfies_table. "Needed for the keyflag
    FIELD-SYMBOLS <ls_dfies> LIKE LINE OF lt_dfies.


    LOOP AT mt_object_table ASSIGNING <ls_object_table>.
      lo_structdescr ?= cl_abap_structdescr=>describe_by_name( <ls_object_table>-tobj_name ).
      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Structure of { <ls_object_table>-tobj_name } corrupt|.
      ENDIF.

      DATA lv_tabname_ddobj TYPE ddobjname.
      lv_tabname_ddobj = <ls_object_table>-tobj_name.
      CALL FUNCTION 'DDIF_NAMETAB_GET'
        EXPORTING
          tabname   = lv_tabname_ddobj    " Name of Table (of the Type)
        TABLES
          dfies_tab = lt_dfies
        EXCEPTIONS
          not_found = 1
          OTHERS    = 2.
      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Structure of { <ls_object_table>-tobj_name } corrupt|.
      ENDIF.

      lt_included_view = lo_structdescr->get_included_view( 1000 ). "There should not be more inclusion-levels than that - even in ERP
      CLEAR <ls_object_table>-field_catalog.

      DATA lv_pos LIKE ls_field_cat_comp-pos.
      CLEAR lv_pos.
      LOOP AT lt_included_view INTO ls_component.
        CLEAR ls_field_cat_comp.

        ADD 1 TO lv_pos.
        ls_field_cat_comp-pos = lv_pos.
        ls_field_cat_comp-name = ls_component-name.
        TRY.
            lo_elemdescr ?= ls_component-type.
          CATCH cx_sy_move_cast_error.
            RAISE EXCEPTION TYPE lcx_obj_exception
              EXPORTING
                iv_text = |Structured database table structures as in { <ls_object_table>-tobj_name } are not expected and not yet supported|.
        ENDTRY.

        READ TABLE lt_dfies ASSIGNING <ls_dfies> WITH KEY fieldname = ls_field_cat_comp-name.
        ASSERT sy-subrc = 0. "Can't imagine why an element may have a different name than the field.

        ls_field_cat_comp-type_kind  = lo_elemdescr->type_kind.
        ls_field_cat_comp-length     = <ls_dfies>-leng. "lo_elemdescr->length funnily return the byte-length
        ls_field_cat_comp-decimals   = lo_elemdescr->decimals.

        ls_field_cat_comp-is_key = <ls_dfies>-keyflag.

        INSERT ls_field_cat_comp INTO TABLE <ls_object_table>-field_catalog.
      ENDLOOP.

    ENDLOOP.

* object methods
    SELECT * FROM objm INTO TABLE mt_object_method
      WHERE objectname = mv_object
      AND   objecttype = co_logical_transport_object.

  ENDMETHOD.

  METHOD get_primary_table.
    READ TABLE mt_object_table INTO rs_object_table WITH KEY prim_table = abap_true.
    IF sy-subrc <> 0.
*    Fallback. For some objects, no primary table is explicitly flagged
*    The, the one with only one key field shall be chosen
      READ TABLE mt_object_table INTO rs_object_table WITH KEY tobjkey = '/&'.
    ENDIF.
    IF rs_object_table IS INITIAL.
      RAISE EXCEPTION TYPE lcx_obj_exception
        EXPORTING
          iv_text = |Object { mv_object } has got no defined primary table|.
    ENDIF.
  ENDMETHOD.

  METHOD export_object.
    DATA lt_table_content TYPE lif_external_object_container=>ty_t_table_content.
    me->before_export( ).

    me->get_current_tables_content(
        EXPORTING io_object_container = io_object_container "this allows the container to store tables one-by-one
        IMPORTING et_table_content    = lt_table_content ).

  ENDMETHOD.

  METHOD import_object.

*  enable backing-up of current table's content
    DATA lt_current_table_content TYPE lif_external_object_container=>ty_t_table_content.
    me->get_current_tables_content( IMPORTING et_table_content = lt_current_table_content ).
    io_object_container->backup_replaced_version( lt_current_table_content ).

*  extract content from container
    DATA lt_imported_table_content TYPE lif_external_object_container=>ty_t_table_content.
    DATA lt_relevant_table TYPE lif_external_object_container=>ty_t_tabname.
    DATA lv_relevant_table LIKE LINE OF lt_relevant_table.
    FIELD-SYMBOLS <ls_local_object_table> LIKE LINE OF mt_object_table.

    CLEAR lt_relevant_table.
    LOOP AT mt_object_table ASSIGNING <ls_local_object_table>.
      lv_relevant_table = <ls_local_object_table>-tobj_name.
      INSERT lv_relevant_table INTO TABLE lt_relevant_table.
    ENDLOOP.

    io_object_container->get_persisted_table_content(
      EXPORTING
        it_relevant_table   = lt_relevant_table
      IMPORTING
        et_table_content  = lt_imported_table_content
    ).

*  validate the content to be imported: Based on the keys of the current system's primary-table,
*  the content to be imported must provide exactly one item!
    DATA ls_primary_table TYPE ty_s_object_table.
    DATA lv_where_primary_table TYPE string.
    FIELD-SYMBOLS <ls_imported_prim_tab_content> LIKE LINE OF lt_imported_table_content.

    ls_primary_table = me->get_primary_table( ).
    lv_where_primary_table = me->get_where_clause( iv_tobj_name     = ls_primary_table-tobj_name ).

    READ TABLE lt_imported_table_content ASSIGNING <ls_imported_prim_tab_content> WITH TABLE KEY tabname = ls_primary_table-tobj_name.
    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE lcx_obj_exception
        EXPORTING
          iv_text = |Primary table { ls_primary_table-tobj_name } not found in imported container |.
    ENDIF.

    DATA lv_count TYPE i.
    FIELD-SYMBOLS <lt_imported_data> TYPE ANY TABLE.
    CLEAR lv_count.

    ASSIGN <ls_imported_prim_tab_content>-data_tab->* TO <lt_imported_data>.
    LOOP AT <lt_imported_data> TRANSPORTING NO FIELDS WHERE (lv_where_primary_table).
      ADD 1 TO lv_count.
      IF lv_count > 1.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Primary table { ls_primary_table-tobj_name } contains more than one instance! |.
      ENDIF.
    ENDLOOP.


*  validate that max one local instance was affected by the import
    SELECT COUNT(*) FROM (ls_primary_table-tobj_name) WHERE (lv_where_primary_table).
    IF sy-dbcnt > 1.
      RAISE EXCEPTION TYPE lcx_obj_exception
        EXPORTING
          iv_text = |More than one instance exists locally in primary table { ls_primary_table-tobj_name }|.
    ENDIF.

*   do the actual update of the local data
*   as the imported data might not feature all aspects of the local object ( not all tables need to be populated)
*   we first purge local object data
    me->delete_object_on_db( ).

*    insert data from imported tables
    FIELD-SYMBOLS <ls_imported_table_content> LIKE LINE OF lt_imported_table_content.
    DATA lv_structures_identical TYPE abap_bool.
    LOOP AT lt_imported_table_content  ASSIGNING <ls_imported_table_content>.
      ASSIGN <ls_imported_table_content>-data_tab->* TO <lt_imported_data>.
      IF lines( <lt_imported_data> ) = 0.
        CONTINUE. "Performance improvement
      ENDIF.
      READ TABLE mt_object_table ASSIGNING <ls_local_object_table> WITH KEY table_name COMPONENTS tobj_name = <ls_imported_table_content>-tabname.
      IF sy-subrc <> 0.
        IF mv_tolerate_additional_tables = abap_true.
          CONTINUE.
        ELSE.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text = |Imported container contains table { <ls_imported_table_content>-tabname } which does not exist in local object definition|.
        ENDIF.
      ENDIF.

      me->val_fieldcatalog_compatibility(
            EXPORTING
              it_imported_fieldcatalog = <ls_imported_table_content>-field_catalog
              it_local_fieldcatalog    = <ls_local_object_table>-field_catalog
            IMPORTING
              ev_is_identical          = lv_structures_identical ).

**      IF lv_structures_identical = abap_true.
**        do_insert(  iv_table_name = <ls_imported_table_content>-tabname
**                    it_data       = <lt_imported_data> ).
**      ELSE.
*      as the structure deviate, it's not an option to directly insert from the imported table.
*      The format needs to be adapted first (even in ABAP, there is no "INSERT INTO CORRESPONDING FIELDS OF dbtab" ;)
      DATA lr_local_format_tab            TYPE REF TO data.
      DATA lr_local_format                TYPE REF TO data.
      FIELD-SYMBOLS <lt_local_format>     TYPE STANDARD TABLE.
      FIELD-SYMBOLS <ls_local_format>     TYPE any.
      FIELD-SYMBOLS <ls_imported_format>  TYPE any.

      CREATE DATA lr_local_format_tab TYPE STANDARD TABLE OF (<ls_imported_table_content>-tabname) WITH DEFAULT KEY.
      ASSIGN lr_local_format_tab->* TO <lt_local_format>.

      CREATE DATA lr_local_format TYPE (<ls_imported_table_content>-tabname).
      ASSIGN lr_local_format->* TO <ls_local_format>.

      LOOP AT <lt_imported_data> ASSIGNING <ls_imported_format>.
        MOVE-CORRESPONDING <ls_imported_format> TO <ls_local_format>.
        INSERT <ls_local_format> INTO TABLE <lt_local_format>.
      ENDLOOP.

      do_insert(    iv_table_name = <ls_imported_table_content>-tabname
                    it_data       = <lt_local_format> ).
**      ENDIF.
    ENDLOOP.


    me->after_import( ).
  ENDMETHOD.


  METHOD before_export.
    FIELD-SYMBOLS <ls_object_method> LIKE LINE OF mt_object_method.
    DATA lt_cts_object_entry    TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.
    DATA ls_cts_object_entry    LIKE LINE OF lt_cts_object_entry.
    DATA lt_cts_key             TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.
    DATA lv_client              TYPE trclient.

    lv_client = sy-mandt.

    ls_cts_object_entry-pgmid  = rs_c_pgmid_r3tr.
    ls_cts_object_entry-object = mv_object.
    ls_cts_object_entry-obj_name = mv_object_name.
    INSERT ls_cts_object_entry INTO TABLE lt_cts_object_entry.

    READ TABLE mt_object_method ASSIGNING <ls_object_method>
      WITH TABLE KEY
        objectname = mv_object
        objecttype = 'L' ##no_text
        method = 'BEFORE_EXP' ##no_text.

    IF sy-subrc = 0.
      CALL FUNCTION <ls_object_method>-methodname
        EXPORTING
          iv_client = lv_client
        TABLES
          tt_e071   = lt_cts_object_entry
          tt_e071k  = lt_cts_key.
    ENDIF.
  ENDMETHOD.


  METHOD after_import.
*  this method re-uses the BW-function-module for executing the After-Import-methods

    DATA lt_log TYPE rs_t_tr_prot.
    DATA lt_cts_object_entry    TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.
    DATA ls_cts_object_entry    LIKE LINE OF lt_cts_object_entry.
    DATA lt_cts_key             TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.
    DATA ls_msg     TYPE rs_s_msg.

    FIELD-SYMBOLS <ls_log> LIKE LINE OF lt_log.

    ls_cts_object_entry-pgmid  = rs_c_pgmid_r3tr.
    ls_cts_object_entry-object = mv_object.
    ls_cts_object_entry-obj_name = mv_object_name.
    INSERT ls_cts_object_entry INTO TABLE lt_cts_object_entry.

    CALL FUNCTION 'RS_AFTER_IMPORT'
      EXPORTING
        i_mode      = rs_c_after_import_mode-activate
      IMPORTING
        e_t_tr_prot = lt_log
      TABLES
        tt_e071     = lt_cts_object_entry
        tt_e071k    = lt_cts_key.

    LOOP AT lt_log ASSIGNING <ls_log>.
      ls_msg-msgid = <ls_log>-ag.
      ls_msg-msgno = <ls_log>-msgnr.
      ls_msg-msgv1 = <ls_log>-var1.
      ls_msg-msgv2 = <ls_log>-var2.
      ls_msg-msgv3 = <ls_log>-var3.
      ls_msg-msgv4 = <ls_log>-var4.
      cl_rso_application_log=>if_rso_application_log~add_message_as_structure( ls_msg ).
    ENDLOOP.
  ENDMETHOD.


  METHOD instance_exists.
*    check whether an object with this name exists in the primary table
    DATA ls_primary_table LIKE LINE OF mt_object_table.
    DATA lv_where_clause TYPE string.

    ls_primary_table = get_primary_table( ).

    lv_where_clause = me->get_where_clause( ls_primary_table-tobj_name ).

    DATA lr_table_line TYPE REF TO data.
    FIELD-SYMBOLS <ls_table_line> TYPE any.
    CREATE DATA lr_table_line TYPE (ls_primary_table-tobj_name).
    ASSIGN lr_table_line->* TO <ls_table_line>.
    SELECT SINGLE * FROM (ls_primary_table-tobj_name) INTO <ls_table_line> WHERE (lv_where_clause).

    rv_exists = boolc( sy-dbcnt > 0 ).

  ENDMETHOD.

  METHOD get_where_clause.
    FIELD-SYMBOLS <ls_object_table> LIKE LINE OF mt_object_table.
    READ TABLE mt_object_table ASSIGNING <ls_object_table> WITH KEY table_name COMPONENTS tobj_name = iv_tobj_name.
    ASSERT sy-subrc = 0.

    DATA lv_objkey_pos                TYPE i.
    DATA lv_next_objkey_pos           TYPE i.
    DATA lv_value_pos                 TYPE i.
    DATA lv_objkey_length             TYPE i.
    DATA lt_objkey                    TYPE ty_t_objkey.
    DATA ls_objkey                    LIKE LINE OF lt_objkey.
    DATA lv_non_value_pos             TYPE numc3.
    DATA lt_key_component             LIKE <ls_object_table>-field_catalog.
    DATA ls_fieldcat_component        LIKE LINE OF lt_key_component.

    CLEAR lt_key_component.
    LOOP AT <ls_object_table>-field_catalog INTO ls_fieldcat_component USING KEY is_key
        WHERE is_key = abap_true.
      INSERT ls_fieldcat_component INTO TABLE lt_key_component.
    ENDLOOP.

*   analyze the object key and compose the key (table)
    CLEAR lt_objkey.
    CLEAR ls_objkey.
    lv_objkey_pos = 0.
    lv_non_value_pos = 1.
    lv_value_pos = 0.
    lv_objkey_length = strlen( <ls_object_table>-tobjkey ).
    WHILE lv_objkey_pos <= lv_objkey_length.
      ls_objkey-num = lv_non_value_pos.
*     command
      IF <ls_object_table>-tobjkey+lv_objkey_pos(1) = '/'.
        IF NOT ls_objkey-value IS INITIAL.
*        We reached the end of a key-definition.
*        this key part may address multiple fields.
*        E. g. six characters may address one boolean field and a five-digit version field.
*        Thus, we need to analyze the remaining key components which have not been covered yet.
          split_value_to_keys(
            EXPORTING
              it_key_component = lt_key_component
            CHANGING
              ct_objkey        = lt_objkey
              cs_objkey        = ls_objkey
              cv_non_value_pos = lv_non_value_pos ).
        ENDIF.
        lv_next_objkey_pos = lv_objkey_pos + 1.
*       '*' means all further key values
        IF <ls_object_table>-tobjkey+lv_next_objkey_pos(1) = '*'.
          ls_objkey-value = '*'.
          INSERT ls_objkey INTO TABLE lt_objkey.
          CLEAR ls_objkey.
          ADD 1 TO lv_non_value_pos.
          ADD 1 TO lv_objkey_pos.
*       object name
        ELSEIF <ls_object_table>-tobjkey+lv_next_objkey_pos(1) = '&'.
          ls_objkey-value = mv_object_name.
* #CP-SUPPRESS: FP no risc
          INSERT ls_objkey INTO TABLE lt_objkey.
          CLEAR ls_objkey.
          ADD 1 TO lv_non_value_pos.
          ADD 1 TO lv_objkey_pos.
*       language
        ELSEIF <ls_object_table>-tobjkey+lv_next_objkey_pos(1) = 'L'.
          ls_objkey-value = sy-langu.
          INSERT ls_objkey INTO TABLE lt_objkey.
          CLEAR ls_objkey.
          ADD 1 TO lv_non_value_pos.
          ADD 1 TO lv_objkey_pos.
*       Client
        ELSEIF <ls_object_table>-tobjkey+lv_next_objkey_pos(1) = 'C'.
          ls_objkey-value = sy-mandt.
          INSERT ls_objkey INTO TABLE lt_objkey.
          CLEAR ls_objkey.
          ADD 1 TO lv_non_value_pos.
          ADD 1 TO lv_objkey_pos.
        ENDIF.
        lv_value_pos = 0.
*     value
      ELSE.
        ls_objkey-value+lv_value_pos(1) = <ls_object_table>-tobjkey+lv_objkey_pos(1).
        ADD 1 TO lv_value_pos.
      ENDIF.

      ADD 1 TO lv_objkey_pos.
    ENDWHILE.
    IF NOT ls_objkey-value IS INITIAL.
      split_value_to_keys(
            EXPORTING
              it_key_component = lt_key_component
            CHANGING
              ct_objkey        = lt_objkey
              cs_objkey        = ls_objkey
              cv_non_value_pos = lv_non_value_pos ).
    ENDIF.

*   compose the where clause
    DATA lv_is_asterix      TYPE abap_bool.
    DATA lv_where_statement TYPE string.
    DATA lv_key_pos         TYPE i.
    DATA lv_value128        TYPE string.
    FIELD-SYMBOLS <ls_table_field> LIKE LINE OF <ls_object_table>-field_catalog.

    lv_is_asterix = abap_false.
    lv_key_pos = 1.

    LOOP AT <ls_object_table>-field_catalog ASSIGNING <ls_table_field>
      USING KEY is_key
      WHERE is_key = abap_true.
* #CP-SUPPRESS: FP no risc
      READ TABLE lt_objkey INTO ls_objkey
        WITH TABLE KEY num = lv_key_pos.
      IF sy-subrc <> 0
      OR <ls_table_field>-name = 'LANGU'.
        CLEAR ls_objkey.
        ADD 1 TO lv_key_pos.
        CONTINUE.
      ENDIF.
      IF ls_objkey-value = '*'.
        lv_is_asterix = rs_c_true.
      ENDIF.
      IF lv_is_asterix = rs_c_true.
        CONTINUE.
      ENDIF.
      IF NOT lv_where_statement IS INITIAL.
* #CP-SUPPRESS: FP no risc
        CONCATENATE lv_where_statement 'AND' INTO lv_where_statement
          SEPARATED BY space.
      ENDIF.
* #CP-SUPPRESS: FP no risc
      CONCATENATE '''' ls_objkey-value '''' INTO lv_value128.
* #CP-SUPPRESS: FP no risc
      CONCATENATE lv_where_statement <ls_table_field>-name '='
        lv_value128 INTO lv_where_statement SEPARATED BY space.
      ADD 1 TO lv_key_pos.
    ENDLOOP.
    rv_where_on_keys = condense( lv_where_statement ).
  ENDMETHOD.


  METHOD get_current_tables_content.

    DATA ls_table_content           LIKE LINE OF et_table_content.
    FIELD-SYMBOLS <ls_object_table> LIKE LINE OF mt_object_table.

    LOOP AT mt_object_table ASSIGNING <ls_object_table>.
      CLEAR ls_table_content.
      ls_table_content-tabname = <ls_object_table>-tobj_name.
      ls_table_content-field_catalog = <ls_object_table>-field_catalog.

*   select from database table using the key
      DATA lv_where_on_keys TYPE string.
      FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
      CREATE DATA ls_table_content-data_tab TYPE STANDARD TABLE OF (<ls_object_table>-tobj_name).
      ASSIGN ls_table_content-data_tab->* TO <lt_data>.

      lv_where_on_keys = me->get_where_clause( <ls_object_table>-tobj_name ).

      SELECT * FROM (<ls_object_table>-tobj_name)
        INTO TABLE <lt_data>
        WHERE (lv_where_on_keys).

*      two consumers: exporting the object to the container and providing all table-content to a container
      IF io_object_container IS NOT INITIAL.
        io_object_container->store_obj_table( ls_table_content ).
      ENDIF.

      IF et_table_content IS SUPPLIED.
        INSERT ls_table_content INTO TABLE et_table_content.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD val_fieldcatalog_compatibility.
*    It is common that between releases the table structures of objects deviate.
*    Usually, in a newer release, fields are being added, rarely removed.
*    But as we cannot know whether the system from which is in-fact being imported
*    is on a more recent release, we can only check whether the structures deviate,
*    not whether there are "additional" or "missing" fields.

*    Types however rarely change. Therefore, this is a second validation.

*    Both validations can be skipped my manipulating member variables.

    DATA ls_local_field_def     LIKE LINE OF it_local_fieldcatalog.
    DATA ls_imported_field_def  LIKE LINE OF it_imported_fieldcatalog.

    DATA lt_imported_fieldcatalog  LIKE it_imported_fieldcatalog. "create a copy in order to delete matching entries from it
    lt_imported_fieldcatalog = it_imported_fieldcatalog.

    ev_is_identical = abap_true.
    LOOP AT it_local_fieldcatalog INTO ls_local_field_def.
      READ TABLE it_imported_fieldcatalog INTO ls_imported_field_def WITH KEY name COMPONENTS name = ls_local_field_def-name.

*      The position of the attribute is not relevant with respect to comparison
      CLEAR: ls_imported_field_def-pos,
             ls_local_field_def-pos.

      IF sy-subrc <> 0.
        ev_is_identical = abap_false.
        IF mv_tolerate_deviating_fields = abap_true.
          CONTINUE. ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        ELSE.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text = |Field { ls_local_field_def-name } does not exist in imported data's structure|.
        ENDIF.
      ENDIF.

      IF ls_imported_field_def NE ls_local_field_def.
        ev_is_identical = abap_false.
        IF mv_tolerate_deviating_types = abap_true.
          CONTINUE. ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        ELSE.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text = |Field { ls_local_field_def-name } has got a different type in local and imported data's structure|.
        ENDIF.
      ENDIF.

      DELETE lt_imported_fieldcatalog WHERE name = ls_local_field_def-name.

    ENDLOOP.

    IF lt_imported_fieldcatalog IS NOT INITIAL. "not all fields matched.
      ev_is_identical = abap_false.
      IF mv_tolerate_deviating_fields = abap_false.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |There are fields in the imported table which do not exist in local data's structure|.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD do_insert.
*  do not operate on the database if executed as part of the unittest.
    INSERT (iv_table_name) FROM TABLE it_data.
  ENDMETHOD.


  METHOD do_delete.
*  do not operate on the database if executed as part of the unittest.
    DELETE FROM (iv_table_name) WHERE (iv_where_on_keys).
  ENDMETHOD.


  METHOD delete_object_on_db.
    DATA lv_where_on_keys TYPE string.
    FIELD-SYMBOLS <ls_local_object_table> LIKE LINE OF mt_object_table.

    LOOP AT mt_object_table ASSIGNING <ls_local_object_table>.
      lv_where_on_keys = me->get_where_clause( <ls_local_object_table>-tobj_name ).

      do_delete(    iv_table_name       = <ls_local_object_table>-tobj_name
                    iv_where_on_keys    = lv_where_on_keys ).

      IF <ls_local_object_table>-prim_table = abap_true.
        ASSERT sy-dbcnt <= 1. "Just to be on the very safe side
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD split_value_to_keys.

    DATA lt_key_component_uncovered TYPE lcl_tlogo_bridge=>ty_s_object_table-field_catalog.
    DATA ls_key_component_uncovered TYPE lif_external_object_container=>ty_s_component.

    lt_key_component_uncovered = it_key_component.
    DATA ls_dummy LIKE LINE OF ct_objkey.
    LOOP AT ct_objkey INTO ls_dummy.
      DELETE lt_key_component_uncovered INDEX 1.
    ENDLOOP.

    DATA ls_objkey_sub     LIKE cs_objkey.
    DATA lv_objkey_sub_pos TYPE i.

    ls_objkey_sub-num = cs_objkey-num.
    lv_objkey_sub_pos = 0.
    LOOP AT lt_key_component_uncovered INTO ls_key_component_uncovered.
      CLEAR ls_objkey_sub-value.
      ls_objkey_sub-value = cs_objkey-value+lv_objkey_sub_pos(ls_key_component_uncovered-length).
      ls_objkey_sub-num = cv_non_value_pos.

      INSERT ls_objkey_sub INTO TABLE ct_objkey.

      ADD ls_key_component_uncovered-length TO lv_objkey_sub_pos.
      ADD 1 TO cv_non_value_pos.
      CLEAR ls_objkey_sub.

      IF lv_objkey_sub_pos = strlen( cs_objkey-value ).
        cs_objkey-num = cv_non_value_pos.
        EXIT. "end splitting - all characters captured
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lcx_obj_exception IMPLEMENTATION.
  METHOD constructor.
    super->constructor( textid   = textid
                        previous = previous ).
    mv_text = iv_text.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_abapgit_xml_container IMPLEMENTATION.

  METHOD lif_external_object_container~store_obj_table.

    DATA lx_abapgit_object TYPE REF TO zcx_abapgit_object.

    FIELD-SYMBOLS <lt_data>             TYPE ANY TABLE.

    ASSIGN is_table_content-data_tab->* TO <lt_data>.
    TRY.
        mo_xml->table_add(  it_table           = <lt_data>
                            iv_name            = |{ is_table_content-tabname }| ).

        mo_xml->table_add(  it_table           = is_table_content-field_catalog
                            iv_name            = |{ is_table_content-tabname }{ co_suffix_fieldcat }| ).
      CATCH zcx_abapgit_object INTO lx_abapgit_object.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text  = lx_abapgit_object->get_text( )
            previous = lx_abapgit_object.
    ENDTRY.
  ENDMETHOD.

  METHOD lif_external_object_container~get_persisted_table_content.
    DATA lx_abapgit_object  TYPE REF TO zcx_abapgit_object.
    DATA ls_table_content   LIKE LINE OF et_table_content.

    FIELD-SYMBOLS <lt_data>             TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_table_content>    LIKE LINE OF et_table_content.

    LOOP AT it_relevant_table INTO ls_table_content-tabname.
      INSERT ls_table_content INTO TABLE et_table_content ASSIGNING <ls_table_content>.

* The content in the external container may deviate with respect to its structure from the local one.
* No! "create data <ls_table_content>-data_tab type STANDARD TABLE OF (<ls_table_content>-tabname) with DEFAULT KEY."
* Thus, the persisted content needs to be read into a structure which matches the fieldcatalog
* with which it has been serialized
      TRY.

          mo_xml->table_read(
               EXPORTING
                 iv_name            = |{ <ls_table_content>-tabname }{ co_suffix_fieldcat }|
                 CHANGING
                   ct_table           = <ls_table_content>-field_catalog
               ).
        CATCH zcx_abapgit_object INTO lx_abapgit_object.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text  = lx_abapgit_object->get_text( )
              previous = lx_abapgit_object.
        CATCH cx_sy_move_cast_error.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text = |Table metadata could not be serialized properly. Could not serialize table { <ls_table_content>-tabname }|.
      ENDTRY.


      DATA lo_tabledescr TYPE REF TO cl_abap_tabledescr.


      create_table_descriptor(
          EXPORTING
              it_field_catalog = <ls_table_content>-field_catalog
            IMPORTING
              eo_tabledescr = lo_tabledescr ).

      CREATE DATA <ls_table_content>-data_tab TYPE HANDLE lo_tabledescr.

      ASSIGN <ls_table_content>-data_tab->* TO <lt_data>.

*    Read the persisted data
      TRY.
          mo_xml->table_read(
          EXPORTING
            iv_name            = |{ <ls_table_content>-tabname }|
            CHANGING
              ct_table           = <lt_data> ).


        CATCH zcx_abapgit_object INTO lx_abapgit_object.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text  = lx_abapgit_object->get_text( )
              previous = lx_abapgit_object.
        CATCH cx_sy_move_cast_error.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text = |Persisted structure deviated from metadata. Could not serialize table { <ls_table_content>-tabname }|.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_external_object_container~backup_replaced_version.
    "todo: not implemented yet.
*    Idea: create a new file containing the backup.
*    Open: How to properly inject the files-object
  ENDMETHOD.

  METHOD constructor.

    IF io_xml IS INITIAL.
      TRY.
          mo_xml = zcl_abapgit_xml_proxy=>create( ).
        CATCH zcx_abapgit_object.  "
          ASSERT 1 = 0.
*           If this fails, ABAPGit XML has a serious issue and should not be processed further.
      ENDTRY.
    ELSE.
      mo_xml = io_xml.
    ENDIF.

  ENDMETHOD.


  METHOD create_table_descriptor.

    DATA lo_structdescr   TYPE REF TO cl_abap_structdescr.
    DATA lt_component     TYPE cl_abap_structdescr=>component_table.
    DATA ls_component     LIKE LINE OF lt_component.
    DATA lx_parameter_invalid_range TYPE REF TO cx_parameter_invalid_range.
    FIELD-SYMBOLS <ls_field_catalog> LIKE LINE OF it_field_catalog.

    CLEAR: ls_component, lt_component, lo_structdescr.
    LOOP AT it_field_catalog ASSIGNING <ls_field_catalog>.
      ls_component-name = <ls_field_catalog>-name.
      TRY.
          CASE <ls_field_catalog>-type_kind.
            WHEN    cl_abap_typedescr=>typekind_char
                OR  cl_abap_typedescr=>typekind_clike
                OR  cl_abap_typedescr=>typekind_csequence.
              ls_component-type = cl_abap_elemdescr=>get_c( <ls_field_catalog>-length ).
            WHEN cl_abap_typedescr=>typekind_date.
              ls_component-type = cl_abap_elemdescr=>get_d( ).
            WHEN cl_abap_typedescr=>typekind_decfloat
            OR  cl_abap_typedescr=>typekind_float.
              ls_component-type = cl_abap_elemdescr=>get_f( ).
            WHEN  cl_abap_typedescr=>typekind_decfloat16.
              ls_component-type = cl_abap_elemdescr=>get_decfloat16( ).
            WHEN  cl_abap_typedescr=>typekind_decfloat34.
              ls_component-type = cl_abap_elemdescr=>get_decfloat34( ).
            WHEN cl_abap_typedescr=>typekind_hex.
              ls_component-type = cl_abap_elemdescr=>get_x( <ls_field_catalog>-length ).
            WHEN  cl_abap_typedescr=>typekind_int
              OR  cl_abap_typedescr=>typekind_int1
              OR  cl_abap_typedescr=>typekind_int2
              OR  cl_abap_typedescr=>typekind_simple.
              ls_component-type = cl_abap_elemdescr=>get_i( ).
            WHEN  cl_abap_typedescr=>typekind_num
              OR  cl_abap_typedescr=>typekind_numeric.
              ls_component-type = cl_abap_elemdescr=>get_n( <ls_field_catalog>-length ).
            WHEN  cl_abap_typedescr=>typekind_packed.
              ls_component-type = cl_abap_elemdescr=>get_p(
                  p_length                   = <ls_field_catalog>-length
                  p_decimals                 = <ls_field_catalog>-decimals
              ).
            WHEN cl_abap_typedescr=>typekind_time.
              ls_component-type = cl_abap_elemdescr=>get_t( ).
            WHEN cl_abap_typedescr=>typekind_string.
              ls_component-type = cl_abap_elemdescr=>get_string( ).
            WHEN cl_abap_typedescr=>typekind_xsequence
              OR cl_abap_typedescr=>typekind_xstring.
              ls_component-type = cl_abap_elemdescr=>get_xstring( ).
            WHEN OTHERS.
              RAISE EXCEPTION TYPE lcx_obj_exception
                EXPORTING
                  iv_text = |Unsupported type_kind { <ls_field_catalog>-type_kind }|.
          ENDCASE.

          INSERT ls_component INTO TABLE lt_component.

        CATCH cx_parameter_invalid_range INTO lx_parameter_invalid_range.
          RAISE EXCEPTION TYPE lcx_obj_exception
            EXPORTING
              iv_text  = |Creation of type_kind { <ls_field_catalog>-type_kind } not possible|
              previous = lx_parameter_invalid_range.
      ENDTRY.
    ENDLOOP.

*    Create a data structure matching the persisted data's table
    DATA lx_sy_struct_creation TYPE REF TO cx_sy_struct_creation.
    TRY.
        lo_structdescr = cl_abap_structdescr=>create( lt_component ).
      CATCH cx_sy_struct_creation INTO lx_sy_struct_creation.  "
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text  = lx_sy_struct_creation->get_text( )
            previous = lx_sy_struct_creation.
    ENDTRY.

    DATA lx_sy_table_creation TYPE REF TO cx_sy_table_creation.
    TRY.
        eo_tabledescr = cl_abap_tabledescr=>create(
            p_line_type          = lo_structdescr
            p_table_kind         = cl_abap_tabledescr=>tablekind_std
        ).
      CATCH cx_sy_table_creation INTO lx_sy_table_creation.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text  = lx_sy_struct_creation->get_text( )
            previous = lx_sy_struct_creation.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_abapgit_st_container IMPLEMENTATION.



  METHOD lif_external_object_container~store_obj_table.
*    sadly, we cannot transform all the DB tables at once,
*    as references are not supported to be serialized in a simple transformation like
*    CALL TRANSFORMATION id
*        SOURCE      objectdatabasecontent = it_table_content
*        RESULT XML  lo_document_temp.
*    we need to create a hierarchy of elements manually
    DATA lo_element_table           TYPE REF TO if_ixml_element.
    DATA lo_element_table_content   TYPE REF TO if_ixml_element.
    DATA lo_element_field_catalog   TYPE REF TO if_ixml_element.
    DATA lo_document_st             TYPE REF TO if_ixml_document.

    FIELD-SYMBOLS <lt_data>         TYPE ANY TABLE.

*****    intended structure
*    <TABLE_NAME> from is_table_content-tabname
*        <fieldCatalog> serialized  is_table_content-field_catalog <fieldCatalog>
*        <TableContent> serialized  is_table_content-data_tab->* </TableContent>
*    </TABLE_NAME>
    lo_element_table =  mo_xml->xml_element( |{ escape_table_name( is_table_content-tabname ) }| ).

*    field-catalog
    lo_element_field_catalog = mo_xml->xml_element( co_element_name_field_catalog ).
    lo_element_table->append_child( lo_element_field_catalog ).

    lo_document_st = cl_ixml=>create( )->create_document( ).

    CALL TRANSFORMATION id
        SOURCE      field_catalog = is_table_content-field_catalog
        RESULT XML  lo_document_st.

    lo_element_field_catalog->append_child( lo_document_st->get_root_element( ) ).

*    Table content
    lo_element_table_content = mo_xml->xml_element( co_element_name_table_content ).
    lo_element_table->append_child( lo_element_table_content ).

    lo_document_st = cl_ixml=>create( )->create_document( ).

    ASSIGN is_table_content-data_tab->* TO <lt_data>.

    CALL TRANSFORMATION id
        SOURCE      data_tab = <lt_data>
        RESULT XML  lo_document_st.
    lo_element_table_content->append_child( lo_document_st->get_root_element( ) ).

    mo_xml->xml_add( lo_element_table ).
  ENDMETHOD.

  METHOD lif_external_object_container~get_persisted_table_content.
    DATA lo_element_table           TYPE REF TO if_ixml_element.
    DATA lo_element_table_content   TYPE REF TO if_ixml_element.
    DATA lo_element_field_catalog   TYPE REF TO if_ixml_element.
    DATA lo_document_st             TYPE REF TO if_ixml_document.
    DATA ls_table_content           LIKE LINE OF et_table_content.
    DATA lo_tabledescr              TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <lt_data>             TYPE ANY TABLE.

*****    intended structure
*    <TABLE_NAME> from is_table_content-tabname
*        <fieldCatalog> serialized  is_table_content-field_catalog <fieldCatalog>
*        <TableContent> serialized  is_table_content-data_tab->* </TableContent>
*    </TABLE_NAME>

    LOOP AT it_relevant_table INTO ls_table_content-tabname.
      CLEAR: ls_table_content-field_catalog, ls_table_content-data_tab.
      lo_element_table =  mo_xml->xml_find( |{ escape_table_name( ls_table_content-tabname ) }| ).
      IF lo_element_table IS INITIAL.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Table { ls_table_content-tabname } not found in imported file. Corrupted file.|.
      ENDIF.

*    field-catalog
      lo_element_field_catalog ?= mo_xml->xml_find( iv_name = co_element_name_field_catalog
                                                   ii_root = lo_element_table ).
      IF lo_element_table IS INITIAL.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Table { ls_table_content-tabname } has no field-catalog. Corrupted file.|.
      ENDIF.

      DATA lo_abap_node TYPE REF TO if_ixml_element.
      lo_abap_node ?= lo_element_field_catalog->create_iterator_filtered(
          depth  = 1    " Iteration Depth, see long text
          filter = lo_element_field_catalog->create_filter_name_ns(
                        name      = |abap|
                        namespace = |http://www.sap.com/abapxml|
                    )
      )->get_next( ).

      lo_document_st = cl_ixml=>create( )->create_document( ).
      lo_document_st->append_child( lo_abap_node ).
      CALL TRANSFORMATION id
        SOURCE XML  lo_document_st
        RESULT      field_catalog = ls_table_content-field_catalog.

      IF ls_table_content-field_catalog IS INITIAL.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Table { ls_table_content-tabname } has no valid field-catalog. Corrupted file.|.
      ENDIF.

*    Table content
      lo_element_table_content = mo_xml->xml_find( iv_name = co_element_name_table_content
                                                   ii_root = lo_element_table ).
      IF lo_element_table_content IS INITIAL.
        RAISE EXCEPTION TYPE lcx_obj_exception
          EXPORTING
            iv_text = |Table { ls_table_content-tabname } has no content-section. Corrupted file.|.
      ENDIF.

      lo_abap_node ?= lo_element_table_content->create_iterator_filtered(
          depth  = 1    " Iteration Depth, see long text
          filter = lo_element_table_content->create_filter_name_ns(
                        name      = |abap|
                        namespace = |http://www.sap.com/abapxml|
                    )
      )->get_next( ).

      create_table_descriptor(
        EXPORTING
          it_field_catalog  = ls_table_content-field_catalog
        IMPORTING
          eo_tabledescr     = lo_tabledescr
      ).

      CREATE DATA ls_table_content-data_tab TYPE HANDLE lo_tabledescr.
      ASSIGN ls_table_content-data_tab->* TO <lt_data>.

      lo_document_st = cl_ixml=>create( )->create_document( ).
      lo_document_st->append_child( lo_abap_node ).

      CALL TRANSFORMATION id
          SOURCE XML  lo_document_st
          RESULT      data_tab = <lt_data>.

      INSERT ls_table_content INTO TABLE et_table_content.
    ENDLOOP.
  ENDMETHOD.

  METHOD escape_table_name.
*    replace namespace slashes
    rv_tabname_escaped = replace( val = iv_tabname  sub = '/'  with = '_-' occ = 0 ). "this is the sequence also used by the ID-transformation
  ENDMETHOD.

ENDCLASS.