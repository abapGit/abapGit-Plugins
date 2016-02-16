CLASS zcl_abapgit_object DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !iv_obj_name       TYPE tadir-obj_name.

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
      RETURNING VALUE(ro_xml_proxy) TYPE REF TO zcl_abapgit_xml_proxy
      RAISING   zcx_abapgit_object.


  PROTECTED SECTION.

    DATA mv_obj_name TYPE tadir-obj_name .

  PRIVATE SECTION.
    DATA mo_files_proxy TYPE REF TO zcl_abapgit_files_proxy .
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT IMPLEMENTATION.


  METHOD constructor.

    mv_obj_name = iv_obj_name.

  ENDMETHOD.


  METHOD create_xml.
*    wrap the xml proxy creation. Advantages:
*    - simplified consumption
*    - ability to move the proxy class implementation
    ro_xml_proxy = zcl_abapgit_xml_proxy=>create(
                     iv_xml   = iv_xml
                     iv_empty = iv_empty ).

  ENDMETHOD.


  METHOD get_files.
    ro_files_proxy = mo_files_proxy.
  ENDMETHOD.


  METHOD set_files.
    mo_files_proxy = new #( io_objects_files ).
  ENDMETHOD.
ENDCLASS.