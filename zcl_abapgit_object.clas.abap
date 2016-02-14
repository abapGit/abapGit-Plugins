CLASS zcl_abapgit_object DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !iv_obj_name       TYPE tadir-obj_name
        !io_helper_factory TYPE REF TO object.

    METHODS get_files FINAL
      RETURNING
        VALUE(ro_files_proxy) TYPE REF TO zcl_abapgit_files_proxy .

    methods set_files final
        importing
            io_objects_files type ref to object.

    METHODS create_xml FINAL
      IMPORTING
                iv_xml              TYPE string OPTIONAL
                iv_empty            TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_xml_proxy) TYPE REF TO zcl_abapgit_xml_proxy.

  PROTECTED SECTION.

    DATA mv_obj_name TYPE tadir-obj_name .

  PRIVATE SECTION.
    DATA mo_files_proxy TYPE REF TO zcl_abapgit_files_proxy .
    DATA mo_helper_factory TYPE REF TO object.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT IMPLEMENTATION.


  METHOD constructor.

    mv_obj_name = iv_obj_name.
    mo_helper_factory = io_helper_factory.

  ENDMETHOD.


  METHOD create_xml.
    DATA lo_xml TYPE REF TO object.
    CALL METHOD mo_helper_factory->('CREATE_XML')
      EXPORTING
        iv_xml   = iv_xml
        iv_empty = iv_empty
      RECEIVING
        ro_xml   = lo_xml.
    ro_xml_proxy = new #( lo_xml ).
  ENDMETHOD.


  METHOD get_files.
    ro_files_proxy = mo_files_proxy.
  ENDMETHOD.


  METHOD set_files.
    mo_files_proxy = new #( io_objects_files ).
  ENDMETHOD.
ENDCLASS.