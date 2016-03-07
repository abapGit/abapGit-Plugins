interface ZIF_ABAPGIT_PLUGIN
  public .


  methods SERIALIZE RAISING zcx_abapgit_object.

  methods DESERIALIZE
    importing
      !IV_PACKAGE type DEVCLASS
    RAISING zcx_abapgit_object.

  methods DELETE RAISING zcx_abapgit_object.

  methods EXISTS
    returning
      value(RV_BOOL) type ABAP_BOOL .

  methods JUMP .
endinterface.