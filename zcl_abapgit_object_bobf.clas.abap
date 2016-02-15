class ZCL_ABAPGIT_OBJECT_BOBF definition
  public
  inheriting from ZCL_ABAPGIT_SAPLINK_ADAPTER
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !IV_OBJ_NAME type TADIR-OBJ_NAME .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_BOBF IMPLEMENTATION.


  METHOD constructor.
    super->constructor(
        iv_saplink_classname = 'ZSAPLINK_BOPF'
        iv_obj_name          = iv_obj_name
     ).
  ENDMETHOD.
ENDCLASS.