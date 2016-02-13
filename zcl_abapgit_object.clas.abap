class ZCL_ABAPGIT_OBJECT definition
  public
  abstract
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !IO_FILES type ref to ZCL_ABAPGIT_FILE_CONTAINER
      !IV_OBJ_NAME type TADIR-OBJ_NAME
      !IV_OBJ_TYPE type TADIR-OBJECT .
protected section.

  data MO_FILES type ref to ZCL_ABAPGIT_FILE_CONTAINER .
  data MV_OBJ_NAME type TADIR-OBJ_NAME .
  data MV_OBJ_TYPE type TADIR-OBJECT .
private section.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT IMPLEMENTATION.


METHOD constructor.

  mo_files = io_files.
  mv_obj_name = iv_obj_name.
  mv_obj_type = iv_obj_type.

ENDMETHOD.
ENDCLASS.