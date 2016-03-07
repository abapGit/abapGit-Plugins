CLASS zcl_abapgit_files_proxy DEFINITION
    PUBLIC
    FINAL
    CREATE PRIVATE
    GLOBAL FRIENDS zcl_abapgit_object.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_file,
             path     TYPE string,
             filename TYPE string,
             data     TYPE xstring,
           END OF ty_file.
    TYPES: ty_files_tt TYPE STANDARD TABLE OF ty_file WITH DEFAULT KEY.

    METHODS:
      get_wrapped_object
        RETURNING VALUE(ro_objects_files) TYPE REF TO object.
    METHODS:
      add_html
        IMPORTING iv_html TYPE string
        RAISING   zcx_abapgit_object,
      read_html
        RETURNING VALUE(rv_html) TYPE string
        RAISING   zcx_abapgit_object,
      add_xml
        IMPORTING iv_extra     TYPE clike OPTIONAL
                  io_xml       TYPE REF TO zcl_abapgit_xml_proxy
                  iv_normalize TYPE sap_bool DEFAULT abap_true
        RAISING   zcx_abapgit_object,
      read_xml
        IMPORTING iv_extra      TYPE clike OPTIONAL
        RETURNING VALUE(ro_xml) TYPE REF TO zcl_abapgit_xml_proxy
        RAISING   zcx_abapgit_object,
      read_abap
        IMPORTING iv_extra       TYPE clike OPTIONAL
                  iv_error       TYPE sap_bool DEFAULT abap_true
        RETURNING VALUE(rt_abap) TYPE abaptxt255_tab
        RAISING   zcx_abapgit_object,
      add_abap
        IMPORTING iv_extra TYPE clike OPTIONAL
                  it_abap  TYPE STANDARD TABLE
        RAISING   zcx_abapgit_object,
      add
        IMPORTING is_file TYPE ty_file,
      get_files
        RETURNING VALUE(rt_files) TYPE ty_files_tt,
      set_files
        IMPORTING it_files TYPE ty_files_tt.

PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: mo_objects_files TYPE REF TO object.

    METHODS constructor
      IMPORTING io_objects_files TYPE REF TO object.

ENDCLASS.



CLASS ZCL_ABAPGIT_FILES_PROXY IMPLEMENTATION.


  METHOD add.
    CALL METHOD mo_objects_files->('ADD')
      EXPORTING
        is_file = is_file.
  ENDMETHOD.


  METHOD add_abap.
    CALL METHOD mo_objects_files->('ADD_ABAP')
      EXPORTING
        iv_extra = iv_extra
        it_abap  = it_abap.
  ENDMETHOD.


  METHOD add_html.
    CALL METHOD mo_objects_files->('ADD_HTML')
      EXPORTING
        iv_html = iv_html.
  ENDMETHOD.


  METHOD add_xml.
    CALL METHOD mo_objects_files->('ADD_XML_FROM_PLUGIN')
      EXPORTING
        iv_extra     = iv_extra
        io_xml       = io_xml->get_wrapped_object( )
        iv_normalize = iv_normalize.
  ENDMETHOD.


  METHOD constructor.
* This class acts as proxy for the local implementation of lcl_files_objects in ZABAPGIT.
* It provides plugins a typed API without duplicating the implementation

* delegate all the method calls to the proxied object.
* potential optimization ( minor priority): Implement a generic RTTI-based
* method call generation so that interface changes would have to be done to the
* definition of this class only
    mo_objects_files = io_objects_files.
  ENDMETHOD.


  METHOD get_files.
    CALL METHOD mo_objects_files->('GET_FILES')
      RECEIVING
        rt_files = rt_files.
  ENDMETHOD.


  METHOD get_wrapped_object.
    ro_objects_files = mo_objects_files.
  ENDMETHOD.


  METHOD read_abap.
    CALL METHOD mo_objects_files->('READ_ABAP')
      EXPORTING
        iv_extra = iv_extra
        iv_error = iv_error
      RECEIVING
        rt_abap  = rt_abap.
  ENDMETHOD.


  METHOD read_html.
    CALL METHOD mo_objects_files->('READ_HTML')
      RECEIVING
        rv_html = rv_html.
  ENDMETHOD.


  METHOD read_xml.
    DATA lo_xml TYPE REF TO object.
    CALL METHOD mo_objects_files->('READ_XML')
      EXPORTING
        iv_extra = iv_extra
      RECEIVING
        ro_xml   = lo_xml.

    ro_xml = NEW #( lo_xml ).
  ENDMETHOD.


  METHOD set_files.
    CALL METHOD mo_objects_files->('SET_FILES')
      EXPORTING
        it_files = it_files.
  ENDMETHOD.
ENDCLASS.