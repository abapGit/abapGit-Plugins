CLASS zcl_abapgit_saplink_adapter DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_object
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abapgit_plugin.

    METHODS constructor
      IMPORTING
        !iv_saplink_classname TYPE classname
        !iv_obj_name          TYPE tadir-obj_name.


  PRIVATE SECTION.
    DATA mo_saplink TYPE REF TO zsaplink.
    DATA mv_saplink_classname TYPE classname.
ENDCLASS.



CLASS ZCL_ABAPGIT_SAPLINK_ADAPTER IMPLEMENTATION.


  METHOD constructor.

    super->constructor( iv_obj_name = iv_obj_name ).

    mv_saplink_classname = iv_saplink_classname.

    TRY.
        CREATE OBJECT mo_saplink TYPE (iv_saplink_classname)
            EXPORTING
                name = CONV string( mv_obj_name ).
      CATCH cx_sy_create_object_error INTO DATA(lx_saplink_not_created).
        "leave mo_saplink_wrapper initial => check this in future calls.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~delete.

    check_valid_saplink.

    TRY.
        mo_saplink->delete( ).
      CATCH zcx_saplink INTO DATA(lx_saplink).
        RAISE EXCEPTION TYPE zcx_abapgit_object EXPORTING iv_text = lx_saplink->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~deserialize.

    check_valid_saplink.

    DATA(ixmldoc) = zsaplink=>convertstringtoixmldoc( get_files( )->read_xml( )->xml_render( ) ).

    TRY.
        mo_saplink->createobjectfromixmldoc(
          EXPORTING
            ixmldocument = ixmldoc    " IF_IXML_DOCUMENT
            devclass     = iv_package
            overwrite    = abap_true "Always overwrite seems to be paradigm in ABAPGit
        ).
      CATCH zcx_saplink INTO DATA(lx_saplink).
        RAISE EXCEPTION TYPE zcx_abapgit_object EXPORTING iv_text = lx_saplink->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~exists.

    rv_bool = mo_saplink->checkexists( ).

  ENDMETHOD.


  METHOD zif_abapgit_plugin~jump ##needed.

  ENDMETHOD.


  METHOD zif_abapgit_plugin~serialize.

    check_valid_saplink.

    TRY.
        DATA(ixmldoc) = mo_saplink->createixmldocfromobject( ).
      CATCH zcx_saplink INTO DATA(lx_saplink).
        IF lx_saplink->textid = zcx_saplink=>not_found.
*            ABAPGit tries to serialize also locally non-existent objects which it found in a git repo=>
*            don't create a file in this case, simply
          RETURN. ">>>>>>>>>>>>>>>>>>>>>>>>>
        ELSE.
          RAISE EXCEPTION TYPE zcx_abapgit_object EXPORTING iv_text = lx_saplink->get_text( ).
        ENDIF.
    ENDTRY.

    get_files( )->add_xml( create_xml( iv_xml = zsaplink=>convertixmldoctostring( ixmldoc ) ) ).
  ENDMETHOD.
ENDCLASS.