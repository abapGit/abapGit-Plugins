CLASS zcl_abapgit_object_xxxx DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_object
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_plugin .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_XXXX IMPLEMENTATION.


  METHOD zif_abapgit_plugin~delete.

    BREAK-POINT.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~deserialize.
    BREAK-POINT.
    data(lv_string) = get_files( )->read_xml( )->xml_render( ).
  ENDMETHOD.


  METHOD zif_abapgit_plugin~exists.

    BREAK-POINT.
    rv_bool = abap_true.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~jump.
    BREAK-POINT.

    WRITE: / 'jump to', mv_obj_name.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~serialize.
*    data lo_xml type ref to zcl_abapgit_xml_proxy.
*    lo_xml = me->create_xml( iv_xml = |<test>XML</test>| ).
*    me->get_files( )->add_xml( io_xml = lo_xml ).
*
**    shorter and without the word "proxy" appearing: inline
    me->get_files( )->add_xml( io_xml = create_xml( iv_xml = |<test>XML</test>| ) ).
  ENDMETHOD.
ENDCLASS.