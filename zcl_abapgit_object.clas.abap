class ZCL_ABAPGIT_OBJECT definition
  public
  abstract
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !IV_OBJ_NAME type TADIR-OBJ_NAME .
  methods GET_FILES
    returning
      value(RO_FILES) type ref to ZCL_ABAPGIT_FILE_CONTAINER .
protected section.

  data MV_OBJ_NAME type TADIR-OBJ_NAME .
  data MO_FILES type ref to ZCL_ABAPGIT_FILE_CONTAINER .
private section.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT IMPLEMENTATION.


METHOD constructor.

  mv_obj_name = iv_obj_name.

  CREATE OBJECT mo_files.

ENDMETHOD.


METHOD get_files.

  ro_files = mo_files.

ENDMETHOD.
ENDCLASS.