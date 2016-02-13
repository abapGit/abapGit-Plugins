class ZCL_ABAPGIT_FILE_CONTAINER definition
  public
  final
  create public .

public section.

  methods ADD_XML .
  methods READ_XML .
  methods CLEAR .
protected section.
private section.

  methods COUNT
    returning
      value(RV_COUNT) type I .
  methods POP
    exporting
      !EV_FILENAME type STRING
      !EV_DATA type XSTRING .
  methods PUSH
    importing
      !IV_FILENAME type STRING
      !IV_DATA type XSTRING .
ENDCLASS.



CLASS ZCL_ABAPGIT_FILE_CONTAINER IMPLEMENTATION.


METHOD add_xml.

* todo, add parameters and code

* this might need to do some PERFORM code IN PROGRAM ZABAPGIT
* in order not to replicate too much code.

ENDMETHOD.


  method CLEAR.
  endmethod.


  method COUNT.
  endmethod.


METHOD pop.

* todo, remove first/last item from internal table and return its values

ENDMETHOD.


METHOD push.

* todo, add to private internal table

ENDMETHOD.


METHOD read_xml.

* todo, add parameters and code

ENDMETHOD.
ENDCLASS.