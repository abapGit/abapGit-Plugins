CLASS lcl_test_bridge DEFINITION INHERITING FROM lcl_tlogo_bridge.
  PUBLIC SECTION.
    METHODS expose_where_clause
      IMPORTING iv_table_name           TYPE sobj_name
      RETURNING VALUE(rv_where_on_keys) TYPE string.
ENDCLASS.

CLASS lcl_test_bridge IMPLEMENTATION.

  METHOD expose_where_clause.
    rv_where_on_keys = get_where_clause( iv_table_name ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_acgr DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS setup RAISING cx_static_check.

    METHODS where_clause_client FOR TESTING RAISING cx_static_check.
    METHODS where_clause_language FOR TESTING RAISING cx_static_check.

    DATA mo_bridge TYPE REF TO lcl_test_bridge.
ENDCLASS.

CLASS ltcl_acgr IMPLEMENTATION.

  METHOD where_clause_client.
    cl_abap_unit_assert=>assert_equals( msg = 'Where clause not expected'
                                        exp = |MANDT = '{ sy-mandt }' AND AGR_NAME = 'ZOBJUT_TEST_DUMMY'|
                                        act = mo_bridge->expose_where_clause( 'AGR_DEFINE' ) ).
  ENDMETHOD.

  METHOD where_clause_language.
    cl_abap_unit_assert=>assert_equals( msg = 'Where clause not expected'
                                        exp = |MANDT = '{ sy-mandt }' AND AGR_NAME = 'ZOBJUT_TEST_DUMMY' AND SPRAS = '{ sy-langu }'|
                                        act = mo_bridge->expose_where_clause( 'AGR_HIERT' ) ).
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT mo_bridge
      EXPORTING
        iv_object      = 'ACGR'
        iv_object_name = 'ZOBJUT_TEST_DUMMY'.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_adso DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS where_clause_one_value_field    FOR TESTING RAISING cx_static_check.
    METHODS where_clause_2_value_fields_st  FOR TESTING RAISING cx_static_check.
    METHODS setup RAISING cx_static_check.

    DATA mo_bridge TYPE REF TO lcl_test_bridge.
ENDCLASS.


CLASS ltcl_adso IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mo_bridge
      EXPORTING
        iv_object      = 'ADSO'
        iv_object_name = 'ZOBJUT_TEST_DUMMY'.
  ENDMETHOD.

  METHOD where_clause_one_value_field.
    cl_abap_unit_assert=>assert_equals( msg = 'Where clause not expected'
                                        exp = |ADSONM = 'ZOBJUT_TEST_DUMMY' AND OBJVERS = 'A'|
                                        act = mo_bridge->expose_where_clause( 'RSOADSO' ) ).

  ENDMETHOD.

  METHOD where_clause_2_value_fields_st.
    cl_abap_unit_assert=>assert_equals( msg = 'Where clause not expected'
                                        exp = |TLOGO = 'ADSO' AND OBJVERS = 'A' AND OBJNM = 'ZOBJUT_TEST_DUMMY'|
                                        act = mo_bridge->expose_where_clause( 'RSOOBJXREF' ) ).

  ENDMETHOD.
ENDCLASS.

CLASS ltcl_bmsm DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS where_clause_values_everywhere  FOR TESTING RAISING cx_static_check.
    METHODS setup RAISING cx_static_check.

    DATA mo_bridge TYPE REF TO lcl_test_bridge.
ENDCLASS.


CLASS ltcl_bmsm IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mo_bridge
      EXPORTING
        iv_object      = 'BMSM'
        iv_object_name = 'ZOBJUT_TEST_DUMMY'.
  ENDMETHOD.

  METHOD where_clause_values_everywhere.
    cl_abap_unit_assert=>assert_equals( msg = 'Where clause not expected'
                                        exp = |PARENT_TYP = 'T' AND PARENT_OBJ = 'ZOBJUT_TEST_DUMMY' AND AS4LOCAL = 'A' AND MODEL_TYP = 'PM'|
                                        act = mo_bridge->expose_where_clause( 'DF40D' ) ).

  ENDMETHOD.

ENDCLASS.