interface ZIF_ABAPGIT_PLUGIN
  public .


  methods SERIALIZE .
  methods DESERIALIZE
    importing
      !IV_PACKAGE type DEVCLASS .
  methods DELETE .
  methods EXISTS
    returning
      value(RV_BOOL) type ABAP_BOOL .
  methods JUMP .
endinterface.