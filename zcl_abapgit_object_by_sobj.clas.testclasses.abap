CLASS ltcl_delete DEFINITION FINAL FOR TESTING  ABSTRACT
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      delete_on_db FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_delete IMPLEMENTATION.

  METHOD delete_on_db.
    DATA lo_bopf_bridge TYPE REF TO zcl_abapgit_object_by_sobj.
    CREATE OBJECT lo_bopf_bridge
      EXPORTING
        iv_obj_type = 'BOBF'
        iv_obj_name = 'ZALICE'.

    lo_bopf_bridge->zif_abapgit_plugin~delete( ).
  ENDMETHOD.

ENDCLASS.