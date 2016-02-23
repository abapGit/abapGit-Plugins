CLASS zcl_abapgit_object_by_sobj DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_object
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abapgit_plugin.

    CLASS-METHODS class_constructor.

    METHODS get_supported_obj_types REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS get_tlogo_bridge
      RETURNING VALUE(ro_tlogo_bridge) TYPE REF TO lcl_tlogo_bridge.

    DATA mo_tlogo_bridge TYPE REF TO lcl_tlogo_bridge.

    CLASS-DATA gt_supported_obj_types TYPE objtyptable.

ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_BY_SOBJ IMPLEMENTATION.


  METHOD class_constructor.
    DATA lt_all_objectname  TYPE STANDARD TABLE OF objh-objectname WITH DEFAULT KEY.
    DATA lv_objectname      LIKE LINE OF lt_all_objectname.
    DATA lv_obj_type        LIKE LINE OF gt_supported_obj_types.

    SELECT objectname FROM objh INTO TABLE lt_all_objectname
           WHERE objecttype = 'L'.

    LOOP AT lt_all_objectname INTO lv_objectname.
      IF strlen( lv_objectname ) <= 4.
        lv_obj_type = lv_objectname.
        INSERT lv_obj_type INTO TABLE gt_supported_obj_types.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_supported_obj_types.
    rt_obj_type = gt_supported_obj_types.
  ENDMETHOD.


  METHOD get_tlogo_bridge.
    IF mo_tlogo_bridge IS INITIAL.

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
    ENDIF.

    ro_tlogo_bridge = mo_tlogo_bridge.
  ENDMETHOD.


  METHOD zif_abapgit_plugin~delete.

    get_tlogo_bridge( )->delete_object_on_db( ).

    me->delete_tadir_entry( ).

  ENDMETHOD.


  METHOD zif_abapgit_plugin~deserialize.
    DATA lo_object_container TYPE REF TO lif_external_object_container.
    DATA lx_obj_exception  TYPE REF TO lcx_obj_exception.

    CREATE OBJECT lo_object_container TYPE lcl_abapgit_xml_container
      EXPORTING
        io_xml = get_files( )->read_xml( ).

    TRY.
        get_tlogo_bridge( )->import_object( lo_object_container ).
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
        rv_bool = get_tlogo_bridge( )->instance_exists( ).

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
        IF get_tlogo_bridge( )->instance_exists( ) = abap_true.

          CREATE OBJECT lo_object_container TYPE lcl_abapgit_xml_container.
          get_tlogo_bridge( )->export_object( lo_object_container ).

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