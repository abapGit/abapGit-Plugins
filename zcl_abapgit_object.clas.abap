CLASS zcl_abapgit_object DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    methods set_item
      IMPORTING
        !iv_obj_type TYPE tadir-object
        !iv_obj_name TYPE tadir-obj_name.

    METHODS get_files FINAL
      RETURNING
        VALUE(ro_files_proxy) TYPE REF TO zcl_abapgit_files_proxy .

    METHODS set_files FINAL
      IMPORTING
        io_objects_files TYPE REF TO object.

    METHODS create_xml FINAL
      IMPORTING
                iv_xml              TYPE string OPTIONAL
                iv_empty            TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_xml_proxy) TYPE REF TO zcl_abapgit_xml_proxy
      RAISING   zcx_abapgit_object.

    METHODS get_supported_obj_types ABSTRACT
      RETURNING VALUE(rt_obj_type) TYPE objtyptable.

  PROTECTED SECTION.
    DATA mv_obj_type TYPE tadir-object.
    DATA mv_obj_name TYPE tadir-obj_name .

    METHODS create_tadir_entry
      IMPORTING
        iv_package TYPE devclass
      RAISING
        zcx_abapgit_object.

    METHODS delete_tadir_entry
      RAISING
        zcx_abapgit_object.

  PRIVATE SECTION.
    DATA mo_files_proxy TYPE REF TO zcl_abapgit_files_proxy .

    METHODS change_object_directory_entry
      IMPORTING
        iv_delete  TYPE abap_bool
        iv_package TYPE devclass
      RAISING
        zcx_abapgit_object.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT IMPLEMENTATION.


  METHOD change_object_directory_entry.

    DATA lv_tadir_object TYPE trobjtype.
    DATA lv_exception_text TYPE string.
    lv_tadir_object = mv_obj_type.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_delete_tadir_entry          = iv_delete    " X - delete object directory entry
        wi_tadir_pgmid                 = 'R3TR'    " Input for TADIR field PGMID
        wi_tadir_object                = lv_tadir_object    " Input for TADIR field OBJECT
        wi_tadir_obj_name              = mv_obj_name    " Input for TADIR field OBJ_NAME
        wi_tadir_devclass              = iv_package
      EXCEPTIONS
        tadir_entry_not_existing       = 1
        tadir_entry_ill_type           = 2
        no_systemname                  = 3
        no_systemtype                  = 4
        original_system_conflict       = 5
        object_reserved_for_devclass   = 6
        object_exists_global           = 7
        object_exists_local            = 8
        object_is_distributed          = 9
        obj_specification_not_unique   = 10
        no_authorization_to_delete     = 11
        devclass_not_existing          = 12
        simultanious_set_remove_repair = 13
        order_missing                  = 14
        no_modification_of_head_syst   = 15
        pgmid_object_not_allowed       = 16
        masterlanguage_not_specified   = 17
        devclass_not_specified         = 18
        specify_owner_unique           = 19
        loc_priv_objs_no_repair        = 20
        gtadir_not_reached             = 21
        object_locked_for_order        = 22
        change_of_class_not_allowed    = 23
        no_change_from_sap_to_tmp      = 24
        OTHERS                         = 25.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_exception_text.
      RAISE EXCEPTION TYPE zcx_abapgit_object
        EXPORTING
          iv_text = lv_exception_text.
    ENDIF.
  ENDMETHOD.


  METHOD create_tadir_entry.
    me->change_object_directory_entry(  iv_package = iv_package
                                        iv_delete = abap_false ).
  ENDMETHOD.


  METHOD create_xml.
*    wrap the xml proxy creation. Advantages:
*    - simplified consumption
*    - ability to move the proxy class implementation
    ro_xml_proxy = zcl_abapgit_xml_proxy=>create(
                     iv_xml   = iv_xml
                     iv_empty = iv_empty ).

  ENDMETHOD.


  METHOD delete_tadir_entry.
    me->change_object_directory_entry(  iv_package = ''
                                        iv_delete = abap_true ).
  ENDMETHOD.


  METHOD get_files.
    ro_files_proxy = mo_files_proxy.
  ENDMETHOD.


  METHOD set_files.
    CREATE OBJECT mo_files_proxy
      EXPORTING
        io_objects_files = io_objects_files.
  ENDMETHOD.


  METHOD set_item.

    mv_obj_type = iv_obj_type.
    mv_obj_name = iv_obj_name.

  ENDMETHOD.
ENDCLASS.