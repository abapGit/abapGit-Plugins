CLASS zcl_abapgit_xml_proxy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_xml TYPE REF TO object
      RAISING   zcx_abapgit_object.

    methods get_wrapped_object
    RETURNING VALUE(ro_xml) type ref to object.

    METHODS element_add
      IMPORTING ig_element TYPE data
                iv_name    TYPE string OPTIONAL
                ii_root    TYPE REF TO if_ixml_element OPTIONAL
      RAISING   zcx_abapgit_object.

    METHODS element_read
      IMPORTING ii_root    TYPE REF TO if_ixml_element OPTIONAL
                iv_name    TYPE string OPTIONAL
      EXPORTING ev_success TYPE abap_bool
      CHANGING  cg_element TYPE data
      RAISING   zcx_abapgit_object.

    METHODS structure_add
      IMPORTING ig_structure TYPE data
                iv_name      TYPE string OPTIONAL
                ii_root      TYPE REF TO if_ixml_element OPTIONAL
      RAISING   zcx_abapgit_object.

    METHODS structure_read
      IMPORTING ii_root      TYPE REF TO if_ixml_element OPTIONAL
                iv_name      TYPE string OPTIONAL
      EXPORTING ev_success   TYPE abap_bool
      CHANGING  cg_structure TYPE data
      RAISING   zcx_abapgit_object.

    METHODS table_add
      IMPORTING it_table TYPE STANDARD TABLE
                iv_name  TYPE string OPTIONAL
                ii_root  TYPE REF TO if_ixml_element OPTIONAL
      RAISING   zcx_abapgit_object.

    METHODS table_read
      IMPORTING ii_root  TYPE REF TO if_ixml_element OPTIONAL
                iv_name  TYPE string OPTIONAL
      CHANGING  ct_table TYPE STANDARD TABLE
      RAISING   zcx_abapgit_object.

    METHODS xml_render
      IMPORTING iv_normalize     TYPE sap_bool DEFAULT abap_true
      RETURNING VALUE(rv_string) TYPE string.

    METHODS xml_element
      IMPORTING iv_name           TYPE string
      RETURNING VALUE(ri_element) TYPE REF TO if_ixml_element.

    METHODS xml_add
      IMPORTING ii_root    TYPE REF TO if_ixml_element OPTIONAL
                ii_element TYPE REF TO if_ixml_element.

    METHODS xml_find
      IMPORTING ii_root           TYPE REF TO if_ixml_element OPTIONAL
                iv_name           TYPE string
      RETURNING VALUE(ri_element) TYPE REF TO if_ixml_element.

  PRIVATE SECTION.
    DATA: mo_xml TYPE REF TO object.
ENDCLASS.



CLASS ZCL_ABAPGIT_XML_PROXY IMPLEMENTATION.


  METHOD constructor.
    mo_xml = io_xml.
  ENDMETHOD.


  METHOD element_add.
    CALL METHOD mo_xml->('ELEMENT_ADD')
      EXPORTING
        ig_element = ig_element
        iv_name    = iv_name
        ii_root    = ii_root.
    .
  ENDMETHOD.


  METHOD element_read.
    CALL METHOD mo_xml->('ELEMENT_READ')
      EXPORTING
        ii_root    = ii_root
        iv_name    = iv_name
      IMPORTING
        ev_success = ev_success
      CHANGING
        cg_element = cg_element.
  ENDMETHOD.


  METHOD get_wrapped_object.
    ro_xml = mo_xml.
  ENDMETHOD.


  METHOD structure_add.
    CALL METHOD mo_xml->('STRUCTURE_ADD')
      EXPORTING
        ig_structure = ig_structure
        iv_name      = iv_name
        ii_root      = ii_root.
  ENDMETHOD.


  METHOD structure_read.
    CALL METHOD mo_xml->('STRUCTURE_READ')
      EXPORTING
        ii_root      = ii_root
        iv_name      = iv_name
      IMPORTING
        ev_success   = ev_success
      CHANGING
        cg_structure = cg_structure.
  ENDMETHOD.


  METHOD table_add.
    CALL METHOD mo_xml->('TABLE_ADD')
      EXPORTING
        it_table = it_table
        iv_name  = iv_name
        ii_root  = ii_root.
  ENDMETHOD.


  METHOD table_read.
    CALL METHOD mo_xml->('TABLE_READ')
      EXPORTING
        ii_root  = ii_root
        iv_name  = iv_name
      CHANGING
        ct_table = ct_table.
  ENDMETHOD.


  METHOD xml_add.
    CALL METHOD mo_xml->('XML_ADD')
      EXPORTING
        ii_root    = ii_root
        ii_element = ii_element.
  ENDMETHOD.


  METHOD xml_element.
    CALL METHOD mo_xml->('XML_ELEMENT')
      EXPORTING
        iv_name    = iv_name
      RECEIVING
        ri_element = ri_element.
  ENDMETHOD.


  METHOD xml_find.
    CALL METHOD mo_xml->('XML_FIND')
      EXPORTING
        ii_root    = ii_root
        iv_name    = iv_name
      RECEIVING
        ri_element = ri_element.
  ENDMETHOD.


  METHOD xml_render.
    CALL METHOD mo_xml->('XML_RENDER')
      EXPORTING
        iv_normalize = iv_normalize
      RECEIVING
        rv_string    = rv_string.
  ENDMETHOD.
ENDCLASS.