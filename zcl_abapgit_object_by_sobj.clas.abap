CLASS zcl_abapgit_object_by_sobj DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_object
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abapgit_plugin.

    METHODS constructor
      IMPORTING
                iv_obj_type TYPE tadir-object
                iv_obj_name TYPE sobj_name
      RAISING   zcx_abapgit_object.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mo_tlogo_bridge TYPE REF TO lcl_tlogo_bridge.

ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_BY_SOBJ IMPLEMENTATION.


  METHOD constructor.
    super->constructor( iv_obj_type   = iv_obj_type
                        iv_obj_name = iv_obj_name ).

    TRY.
        DATA lx_bridge_creation TYPE REF TO lcx_obj_exception.
        CREATE OBJECT mo_tlogo_bridge
          EXPORTING
            iv_object      = mv_obj_type
            iv_object_name = mv_obj_name.
      CATCH lcx_obj_exception INTO lx_bridge_creation.
        RAISE EXCEPTION TYPE zcx_abapgit_object
          EXPORTING
            iv_text  = lx_bridge_creation->get_text( )
            previous = lx_bridge_creation.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~delete.

    mo_tlogo_bridge->delete_object_on_db( ).

    me->delete_tadir_entry( ).

  ENDMETHOD.


  METHOD zif_abapgit_plugin~deserialize.
    DATA lo_object_container TYPE REF TO lif_external_object_container.
    DATA lx_obj_exception  TYPE REF TO lcx_obj_exception.

    CREATE OBJECT lo_object_container TYPE lcl_abapgit_xml_container
      EXPORTING
        io_xml = get_files( )->read_xml( ).

    TRY.
        mo_tlogo_bridge->import_object( lo_object_container ).
      CATCH lcx_obj_exception INTO lx_obj_exception.
        RAISE EXCEPTION TYPE zcx_abapgit_object
          EXPORTING
            iv_text  = |Import of { mv_obj_type } { mv_obj_name } failed|
            previous = lx_obj_exception.
    ENDTRY.

    me->create_tadir_entry( iv_package = iv_package ).
  ENDMETHOD.


  METHOD zif_abapgit_plugin~exists.
    DATA lx_obj_exception  TYPE REF TO lcx_obj_exception.

    TRY.
        rv_bool = mo_tlogo_bridge->instance_exists( ).

      CATCH lcx_obj_exception INTO lx_obj_exception.
        rv_bool = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_abapgit_plugin~jump.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~serialize.
    DATA lo_object_container TYPE REF TO lcl_abapgit_xml_container.
    DATA lx_obj_exception  TYPE REF TO lcx_obj_exception.

    TRY.
        IF mo_tlogo_bridge->instance_exists( ) = abap_true.

          CREATE OBJECT lo_object_container TYPE lcl_abapgit_xml_container.
          mo_tlogo_bridge->export_object( lo_object_container ).

          get_files( )->add_xml( lo_object_container->mo_xml ).

        ENDIF. "No else needed - if the object does not exist, we'll not serialize anything
      CATCH lcx_obj_exception INTO lx_obj_exception.
        RAISE EXCEPTION TYPE zcx_abapgit_object
          EXPORTING
            iv_text  = lx_obj_exception->get_text( )
            previous = lx_obj_exception.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.