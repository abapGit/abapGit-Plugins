CLASS zcl_abapgit_object_bobf DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_saplink_adapter
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      importing
        !iv_obj_name          TYPE tadir-obj_name
        !io_helper_factory    type ref to object.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_BOBF IMPLEMENTATION.


  METHOD constructor.
    super->constructor(
        iv_saplink_classname = 'ZSAPLINK_BOPF'
        iv_obj_name          = iv_obj_name
        io_helper_factory    = io_helper_factory
     ).
  ENDMETHOD.
ENDCLASS.